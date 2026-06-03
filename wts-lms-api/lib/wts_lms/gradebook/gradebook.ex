defmodule WtsLms.Gradebook do
  @moduledoc """
  Deterministic WTS gradebook calculations and CSV export for core coursework.
  """

  @default_grading_scheme [
    {"A", "93.0"},
    {"A-", "90.0"},
    {"B+", "87.0"},
    {"B", "83.0"},
    {"B-", "80.0"},
    {"C", "70.0"},
    {"F", "0.0"}
  ]
  @active_enrollment_states [:active, "active"]

  def student_view(course_id, student_user_id, opts \\ []) do
    with {:ok, course} <- find_one(Keyword.get(opts, :courses, []), course_id, "course missing"),
         {:ok, student} <-
           find_one(Keyword.get(opts, :users, []), student_user_id, "student missing") do
      {:ok, build_view(course, student, :student, opts)}
    end
  end

  def teacher_view(course_id, student_user_id, opts \\ []) do
    with {:ok, course} <- find_one(Keyword.get(opts, :courses, []), course_id, "course missing"),
         {:ok, student} <-
           find_one(Keyword.get(opts, :users, []), student_user_id, "student missing") do
      {:ok, build_view(course, student, :teacher, opts)}
    end
  end

  def export_csv(course_id, opts \\ []) do
    with {:ok, course} <- find_one(Keyword.get(opts, :courses, []), course_id, "course missing") do
      assignments = course_assignments(course_id, :teacher, opts)
      assignment_headers = Enum.map(assignments, &(value(&1, :title) || "Untitled Assignment"))

      headers =
        [
          "student_id",
          "sis_user_id",
          "student_name",
          "email",
          "course_id",
          "course_name",
          "section"
        ] ++ assignment_headers ++ ["current_final_percentage", "final_letter_display", "notes"]

      rows =
        course_students(course_id, opts)
        |> Enum.map(fn student -> csv_row(course, student, assignments, opts) end)

      {:ok, Enum.map_join([headers] ++ rows, "\n", &csv_line/1) <> "\n"}
    end
  end

  def final_letter(final_percentage, opts \\ []) do
    percentage = decimal(final_percentage)

    opts
    |> Keyword.get(:grading_scheme, @default_grading_scheme)
    |> Enum.map(fn {letter, threshold} -> {letter, decimal(threshold)} end)
    |> Enum.sort_by(fn {_letter, threshold} -> threshold end, {:desc, Decimal})
    |> Enum.find_value("F", fn {letter, threshold} ->
      if Decimal.compare(percentage, threshold) in [:gt, :eq], do: letter
    end)
  end

  defp build_view(course, student, audience, opts) do
    assignments = course_assignments(value(course, :id), audience, opts)
    grade_items = Keyword.get(opts, :grade_items, [])
    grades = Keyword.get(opts, :grades, [])

    groups =
      value(course, :id)
      |> course_groups(opts)
      |> Enum.map(&group_view(&1, assignments, grade_items, grades, student, audience, opts))
      |> Enum.reject(&is_nil/1)

    final_percentage =
      final_percentage(groups, assignments, grade_items, grades, student, audience, opts)

    %{
      course: %{id: value(course, :id), name: value(course, :name), code: value(course, :code)},
      student: student_payload(student),
      final_percentage: format_decimal(final_percentage),
      letter_display: final_letter(final_percentage, opts),
      groups: groups
    }
  end

  defp group_view(group, assignments, grade_items, grades, student, audience, opts) do
    entries =
      assignments
      |> Enum.filter(&(value(&1, :assignment_group_id) == value(group, :id)))
      |> Enum.map(&assignment_entry(&1, grade_items, grades, student, audience, opts))

    entries = apply_drop_rule(entries, value(group, :drop_rule))
    included = Enum.filter(entries, & &1.counts?)

    %{
      id: value(group, :id),
      name: value(group, :name),
      weight: to_string(value(group, :weight) || ""),
      percentage:
        format_decimal(percentage(sum(included, :earned_points), sum(included, :possible_points))),
      assignments: entries
    }
  end

  defp assignment_entry(assignment, grade_items, grades, student, audience, opts) do
    grade_item = Enum.find(grade_items, &(value(&1, :assignment_id) == value(assignment, :id)))
    grade = selected_grade(grade_item, grades, student)

    possible =
      decimal(
        value(assignment, :points_possible) || value(grade_item || %{}, :points_possible) || "0"
      )

    published = published?(assignment)
    state = entry_state(assignment, grade, audience)
    {earned, counts?, display} = score_for(state, grade, possible, opts)

    %{
      id: value(assignment, :id),
      title: value(assignment, :title),
      points_possible: format_decimal(possible),
      earned_points: earned,
      possible_points: possible,
      display_score: display,
      state: state,
      counts?: counts? && published,
      grading_comments: value(grade || %{}, :grading_comments) || [],
      posted_at: value(grade || %{}, :posted_at),
      notes: notes_for(state, published)
    }
  end

  defp selected_grade(nil, _grades, _student), do: nil

  defp selected_grade(grade_item, grades, student) do
    grades
    |> Enum.filter(
      &(value(&1, :grade_item_id) == value(grade_item, :id) &&
          value(&1, :student_user_id) == value(student, :id))
    )
    |> Enum.sort_by(
      &{value(&1, :posted_at) || value(&1, :updated_at) || "", value(&1, :submission_id) || ""},
      :desc
    )
    |> List.first()
  end

  defp score_for(:unpublished, grade, _possible, _opts),
    do:
      {decimal(value(grade || %{}, :points)), false,
       if(grade, do: format_decimal(decimal(value(grade, :points))), else: "unpublished")}

  defp score_for(:ungraded, _grade, _possible, _opts), do: {decimal("0"), false, "ungraded"}
  defp score_for(:unposted, _grade, _possible, _opts), do: {decimal("0"), false, "ungraded"}
  defp score_for(:excused, _grade, _possible, _opts), do: {decimal("0"), false, "excused"}

  defp score_for(:missing, grade, _possible, opts) do
    case Keyword.get(opts, :missing_policy) do
      nil ->
        {decimal("0"), false, "missing"}

      policy ->
        score = decimal(value(policy, :score) || value(grade, :points) || "0")
        {score, true, format_decimal(score)}
    end
  end

  defp score_for(:late, grade, _possible, opts) do
    score = decimal(value(grade, :points))
    deduction = decimal(value(Keyword.get(opts, :late_policy, %{}), :deduction_percent))

    earned =
      if Decimal.compare(deduction, decimal("0")) == :gt do
        Decimal.sub(score, Decimal.div(Decimal.mult(score, deduction), decimal("100")))
      else
        score
      end

    {earned, true, format_decimal(earned)}
  end

  defp score_for(_state, grade, _possible, _opts) do
    score = decimal(value(grade || %{}, :points))
    {score, not is_nil(grade), if(grade, do: format_decimal(score), else: "ungraded")}
  end

  defp apply_drop_rule(entries, nil), do: entries

  defp apply_drop_rule(entries, rule) do
    drop_count = value(rule, :drop_lowest) || value(rule, :drop_lowest_scores) || 0

    droppable =
      Enum.filter(
        entries,
        &(&1.counts? && Decimal.compare(&1.possible_points, decimal("0")) == :gt)
      )

    drop_ids =
      droppable
      |> Enum.sort_by(
        fn entry -> percentage(entry.earned_points, entry.possible_points) end,
        Decimal
      )
      |> Enum.take(drop_count)
      |> MapSet.new(& &1.id)

    Enum.map(entries, fn entry ->
      if MapSet.member?(drop_ids, entry.id),
        do: %{entry | counts?: false, state: :dropped, notes: append_note(entry.notes, "dropped")},
        else: entry
    end)
  end

  defp final_percentage(groups, assignments, grade_items, grades, student, audience, opts) do
    weighted = Enum.filter(groups, &(Decimal.compare(decimal(&1.weight), decimal("0")) == :gt))

    if weighted == [] do
      included =
        assignments
        |> Enum.map(&assignment_entry(&1, grade_items, grades, student, audience, opts))
        |> Enum.filter(& &1.counts?)

      percentage(sum(included, :earned_points), sum(included, :possible_points))
    else
      total_weight = sum(weighted, :weight)

      weighted_sum =
        Enum.reduce(weighted, decimal("0"), fn group, acc ->
          Decimal.add(acc, Decimal.mult(decimal(group.percentage), decimal(group.weight)))
        end)

      if Decimal.compare(total_weight, decimal("0")) == :eq,
        do: decimal("0"),
        else: Decimal.div(weighted_sum, total_weight)
    end
  end

  defp csv_row(course, student, assignments, opts) do
    {:ok, view} = teacher_view(value(course, :id), value(student, :id), opts)
    entries = view.groups |> Enum.flat_map(& &1.assignments) |> Map.new(&{&1.id, &1})
    section = section_name(student, opts)

    notes =
      entries
      |> Map.values()
      |> Enum.map(& &1.notes)
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.join("; ")

    [
      value(student, :id),
      value(student, :sis_user_id),
      value(student, :display_name),
      value(student, :email),
      value(course, :id),
      value(course, :name),
      section
    ] ++
      Enum.map(assignments, &(Map.get(entries, value(&1, :id), %{}).display_score || "")) ++
      [view.final_percentage, view.letter_display, notes]
  end

  defp course_students(course_id, opts) do
    user_by_id = Map.new(Keyword.get(opts, :users, []), &{value(&1, :id), &1})

    opts
    |> Keyword.get(:enrollments, [])
    |> Enum.filter(
      &(value(&1, :course_id) == course_id && value(&1, :state) in @active_enrollment_states)
    )
    |> Enum.map(&Map.get(user_by_id, value(&1, :user_id)))
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(&{value(&1, :display_name) || "", value(&1, :id) || ""})
  end

  defp section_name(student, opts) do
    enrollment =
      Enum.find(
        Keyword.get(opts, :enrollments, []),
        &(value(&1, :user_id) == value(student, :id))
      )

    section =
      Enum.find(
        Keyword.get(opts, :sections, []),
        &(value(&1, :id) == value(enrollment || %{}, :section_id))
      )

    value(section || %{}, :name) || ""
  end

  defp course_assignments(course_id, audience, opts) do
    opts
    |> Keyword.get(:assignments, [])
    |> Enum.filter(&(value(&1, :course_id) == course_id))
    |> Enum.filter(&(audience != :student || published?(&1)))
    |> Enum.sort_by(&(value(&1, :title) || ""))
  end

  defp course_groups(course_id, opts) do
    opts
    |> Keyword.get(:assignment_groups, [])
    |> Enum.filter(&(value(&1, :course_id) == course_id))
    |> Enum.sort_by(&{value(&1, :position) || 0, value(&1, :name) || ""})
  end

  defp entry_state(assignment, nil, _audience),
    do: if(published?(assignment), do: :ungraded, else: :unpublished)

  defp entry_state(assignment, grade, _audience),
    do: if(published?(assignment), do: normalize(value(grade, :state)), else: :unpublished)

  defp notes_for(:excused, _published), do: "excused"
  defp notes_for(:missing, _published), do: "missing"
  defp notes_for(:unpublished, false), do: "unpublished"
  defp notes_for(_state, _published), do: ""
  defp append_note("", note), do: note
  defp append_note(notes, note), do: notes <> "; " <> note

  defp student_payload(student),
    do: %{
      id: value(student, :id),
      sis_user_id: value(student, :sis_user_id),
      display_name: value(student, :display_name),
      email: value(student, :email)
    }

  defp percentage(earned, possible) do
    if Decimal.compare(decimal(possible), decimal("0")) == :eq,
      do: decimal("0"),
      else: Decimal.mult(Decimal.div(decimal(earned), decimal(possible)), decimal("100"))
  end

  defp sum(items, field),
    do:
      Enum.reduce(items, decimal("0"), fn item, acc ->
        Decimal.add(acc, decimal(value(item, field)))
      end)

  defp decimal(%Decimal{} = value), do: value
  defp decimal(nil), do: Decimal.new("0")
  defp decimal(value), do: Decimal.new(to_string(value))

  defp format_decimal(value),
    do: value |> Decimal.round(2) |> Decimal.to_string(:normal) |> ensure_two_decimals()

  defp ensure_two_decimals(value),
    do: if(String.contains?(value, "."), do: pad_decimals(value), else: value <> ".00")

  defp pad_decimals(value),
    do:
      value
      |> String.split(".")
      |> then(fn [whole, fraction] ->
        whole <> "." <> String.pad_trailing(String.slice(fraction, 0, 2), 2, "0")
      end)

  defp csv_line(values), do: values |> Enum.map(&csv_cell/1) |> Enum.join(",")
  defp csv_cell(value), do: value |> to_string() |> String.replace("\"", "\"\"") |> quote_csv()

  defp quote_csv(value),
    do: if(String.contains?(value, [",", "\"", "\n"]), do: "\"" <> value <> "\"", else: value)

  defp find_one(items, id, reason_code) do
    case Enum.find(items, &(value(&1, :id) == id)) do
      nil -> {:error, %{status: 404, reason_code: reason_code}}
      item -> {:ok, item}
    end
  end

  defp published?(entity), do: normalize(value(entity, :status)) in [:published, :active, nil]
  defp normalize("active"), do: :active
  defp normalize("published"), do: :published
  defp normalize("unpublished"), do: :unpublished
  defp normalize("posted"), do: :posted
  defp normalize("unposted"), do: :unposted
  defp normalize("ungraded"), do: :ungraded
  defp normalize("missing"), do: :missing
  defp normalize("excused"), do: :excused
  defp normalize("late"), do: :late
  defp normalize("extra_credit"), do: :extra_credit
  defp normalize("dropped"), do: :dropped
  defp normalize(value) when is_binary(value), do: value
  defp normalize(value), do: value
  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
