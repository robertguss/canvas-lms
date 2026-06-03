defmodule WtsLms.GradebookTest do
  use ExUnit.Case, async: true

  alias WtsLms.Gradebook
  alias WtsLms.Gradebook.Verify

  alias WtsLms.Schema.{
    Assignment,
    AssignmentGroup,
    Course,
    Enrollment,
    Grade,
    GradeItem,
    Section,
    User
  }

  @fixture Path.expand("../../fixtures/gradebook/weighted_groups.json", __DIR__)

  test "weighted assignment groups calculate final percentage and letter display" do
    fixture = weighted_fixture()

    assert {:ok, view} =
             Gradebook.student_view(fixture.course.id, fixture.student.id, opts(fixture))

    assert view.final_percentage == "89.00"
    assert view.letter_display == "B+"

    assert Enum.map(view.groups, &{&1.name, &1.percentage, &1.weight}) == [
             {"Essays", "90.00", "40.0"},
             {"Exams", "88.33", "60.0"}
           ]
  end

  test "ungraded submitted work is visible but does not count until posted" do
    fixture = weighted_fixture()

    ungraded =
      assignment(
        "assignment-ungraded",
        fixture.course,
        hd(fixture.assignment_groups),
        "Ungraded Reflection",
        "100.0"
      )

    grade_item = grade_item(ungraded)

    assert {:ok, view} =
             Gradebook.teacher_view(
               fixture.course.id,
               fixture.student.id,
               opts(fixture,
                 assignments: fixture.assignments ++ [ungraded],
                 grade_items: fixture.grade_items ++ [grade_item]
               )
             )

    entry = find_assignment(view, "assignment-ungraded")
    assert entry.display_score == "ungraded"
    assert entry.state == :ungraded
    refute entry.counts?
    assert view.final_percentage == "89.00"
  end

  test "missing work only applies a score when a missing policy is configured" do
    fixture = weighted_fixture()

    missing =
      assignment(
        "assignment-missing",
        fixture.course,
        hd(fixture.assignment_groups),
        "Missing Reading",
        "10.0"
      )

    grade_item = grade_item(missing)
    missing_grade = grade("grade-missing", missing, fixture.student, nil, state: :missing)

    without_policy =
      opts(fixture,
        assignments: fixture.assignments ++ [missing],
        grade_items: fixture.grade_items ++ [grade_item],
        grades: fixture.grades ++ [missing_grade]
      )

    assert {:ok, view_without_policy} =
             Gradebook.teacher_view(fixture.course.id, fixture.student.id, without_policy)

    missing_without_policy = find_assignment(view_without_policy, "assignment-missing")
    assert missing_without_policy.display_score == "missing"
    refute missing_without_policy.counts?
    assert view_without_policy.final_percentage == "89.00"

    assert {:ok, view_with_policy} =
             Gradebook.teacher_view(
               fixture.course.id,
               fixture.student.id,
               Keyword.put(without_policy, :missing_policy, %{score: "0.0"})
             )

    missing_with_policy = find_assignment(view_with_policy, "assignment-missing")
    assert missing_with_policy.display_score == "0.00"
    assert missing_with_policy.counts?
    assert view_with_policy.final_percentage == "83.00"
  end

  test "excused late resubmitted extra-credit and dropped scores are deterministic" do
    fixture = weighted_fixture()
    group = hd(fixture.assignment_groups)
    excused = assignment("assignment-excused", fixture.course, group, "Excused Practice", "10.0")
    late = assignment("assignment-late", fixture.course, group, "Late Reading", "10.0")

    resubmitted =
      assignment("assignment-resubmitted", fixture.course, group, "Resubmitted Essay", "10.0")

    extra_credit =
      assignment("assignment-extra-credit", fixture.course, group, "Extra Credit", "0.0")

    dropped = assignment("assignment-dropped", fixture.course, group, "Dropped Quiz", "10.0")
    assignments = fixture.assignments ++ [excused, late, resubmitted, extra_credit, dropped]

    grade_items =
      fixture.grade_items ++
        Enum.map([excused, late, resubmitted, extra_credit, dropped], &grade_item/1)

    grades =
      fixture.grades ++
        [
          grade("grade-excused", excused, fixture.student, nil, state: :excused),
          grade("grade-late", late, fixture.student, "10.0", state: :late),
          grade("grade-resubmitted-old", resubmitted, fixture.student, "6.0",
            posted_at: ~U[2027-01-13 12:00:00Z]
          ),
          grade("grade-resubmitted-new", resubmitted, fixture.student, "9.0",
            posted_at: ~U[2027-01-14 12:00:00Z],
            grading_comments: [%{body: "Improved."}]
          ),
          grade("grade-extra-credit", extra_credit, fixture.student, "2.0", state: :extra_credit),
          grade("grade-dropped", dropped, fixture.student, "1.0")
        ]

    [essay_group, exams_group] = fixture.assignment_groups
    essay_group = %{essay_group | drop_rule: %{drop_lowest: 1}}

    assert {:ok, view} =
             Gradebook.teacher_view(
               fixture.course.id,
               fixture.student.id,
               opts(fixture,
                 assignment_groups: [essay_group, exams_group],
                 assignments: assignments,
                 grade_items: grade_items,
                 grades: grades,
                 late_policy: %{deduction_percent: "10.0"}
               )
             )

    assert find_assignment(view, "assignment-excused").display_score == "excused"
    assert find_assignment(view, "assignment-late").display_score == "9.00"
    assert find_assignment(view, "assignment-resubmitted").display_score == "9.00"

    assert find_assignment(view, "assignment-resubmitted").grading_comments == [
             %{body: "Improved."}
           ]

    assert find_assignment(view, "assignment-extra-credit").display_score == "2.00"
    assert find_assignment(view, "assignment-dropped").state == :dropped
    refute find_assignment(view, "assignment-dropped").counts?
    assert view.final_percentage == "90.14"
  end

  test "unpublished assignments are not visible to students but explicit for teachers" do
    fixture = weighted_fixture()

    unpublished =
      Assignment.new!(%{
        id: "assignment-unpublished",
        course_id: fixture.course.id,
        assignment_group_id: hd(fixture.assignment_groups).id,
        title: "Draft Assignment",
        points_possible: "10.0",
        status: :unpublished
      })

    grade_item = grade_item(unpublished)
    draft_grade = grade("grade-draft", unpublished, fixture.student, "10.0")

    shared_opts =
      opts(fixture,
        assignments: fixture.assignments ++ [unpublished],
        grade_items: fixture.grade_items ++ [grade_item],
        grades: fixture.grades ++ [draft_grade]
      )

    assert {:ok, student_view} =
             Gradebook.student_view(fixture.course.id, fixture.student.id, shared_opts)

    assert find_assignment(student_view, "assignment-unpublished") == nil
    assert student_view.final_percentage == "89.00"

    assert {:ok, teacher_view} =
             Gradebook.teacher_view(fixture.course.id, fixture.student.id, shared_opts)

    draft_entry = find_assignment(teacher_view, "assignment-unpublished")
    assert draft_entry.state == :unpublished
    refute draft_entry.counts?
    assert teacher_view.final_percentage == "89.00"
  end

  test "CSV export uses fixed headers stable rows utf8 and no private fields" do
    fixture = weighted_fixture()

    second_student =
      User.new!(%{
        id: "student-2",
        sis_user_id: "S200",
        display_name: "Abel Student",
        email: "abel@example.edu"
      })

    second_enrollment =
      Enrollment.new!(%{
        id: "enrollment-2",
        course_id: fixture.course.id,
        section_id: "section-1",
        user_id: second_student.id,
        role_id: "role-student",
        state: :active
      })

    grades =
      fixture.grades ++
        Enum.map(fixture.assignments, &grade("grade-second-#{&1.id}", &1, second_student, "10.0"))

    assert {:ok, csv} =
             Gradebook.export_csv(
               fixture.course.id,
               opts(fixture,
                 users: fixture.users ++ [second_student],
                 enrollments: fixture.enrollments ++ [second_enrollment],
                 grades: grades
               )
             )

    assert String.valid?(csv)
    [header | rows] = String.split(csv, "\n", trim: true)

    assert header ==
             "student_id,sis_user_id,student_name,email,course_id,course_name,section,Essay,Final Exam,Midterm,current_final_percentage,final_letter_display,notes"

    assert Enum.map(rows, &(String.split(&1, ",") |> Enum.at(0))) == ["student-2", "student-1"]
    refute csv =~ "audit_note"
    refute csv =~ "grader_user_id"
  end

  test "fixture verifier succeeds for matching expected output and fails for mismatch" do
    assert {:ok, report} = Verify.run_file(@fixture)
    assert report.final_percentage == "89.00"
    assert report.letter_display == "B+"

    bad_fixture = Path.join(System.tmp_dir!(), "weighted_groups_mismatch.json")

    File.write!(
      bad_fixture,
      String.replace(
        File.read!(@fixture),
        ~s("final_percentage": "89.00"),
        ~s("final_percentage": "1.00")
      )
    )

    assert {:error, %{reason_code: "gradebook fixture mismatch"}} = Verify.run_file(bad_fixture)
  end

  defp weighted_fixture do
    course =
      Course.new!(%{
        id: "course-1",
        account_id: "acct-1",
        term_id: "term-1",
        sis_course_id: "THEO-101",
        name: "Foundations",
        code: "THEO-101"
      })

    section =
      Section.new!(%{
        id: "section-1",
        course_id: course.id,
        sis_section_id: "THEO-101-A",
        name: "A"
      })

    student =
      User.new!(%{
        id: "student-1",
        sis_user_id: "S100",
        display_name: "Student One",
        email: "student@example.edu"
      })

    enrollment =
      Enrollment.new!(%{
        id: "enrollment-1",
        course_id: course.id,
        section_id: section.id,
        user_id: student.id,
        role_id: "role-student",
        state: :active
      })

    essays =
      AssignmentGroup.new!(%{
        id: "group-essays",
        course_id: course.id,
        name: "Essays",
        weight: "40.0",
        position: 1
      })

    exams =
      AssignmentGroup.new!(%{
        id: "group-exams",
        course_id: course.id,
        name: "Exams",
        weight: "60.0",
        position: 2
      })

    essay = assignment("assignment-essay", course, essays, "Essay", "50.0")
    midterm = assignment("assignment-midterm", course, exams, "Midterm", "100.0")
    final_exam = assignment("assignment-final", course, exams, "Final Exam", "50.0")
    grade_items = Enum.map([essay, midterm, final_exam], &grade_item/1)

    grades = [
      grade("grade-essay", essay, student, "45.0"),
      grade("grade-midterm", midterm, student, "90.0"),
      grade("grade-final", final_exam, student, "42.5")
    ]

    %{
      course: course,
      sections: [section],
      student: student,
      users: [student],
      enrollments: [enrollment],
      assignment_groups: [essays, exams],
      assignments: [essay, midterm, final_exam],
      grade_items: grade_items,
      grades: grades
    }
  end

  defp opts(fixture, extra \\ []) do
    Keyword.merge(
      [
        courses: [fixture.course],
        sections: fixture.sections,
        users: fixture.users,
        enrollments: fixture.enrollments,
        assignment_groups: fixture.assignment_groups,
        assignments: fixture.assignments,
        grade_items: fixture.grade_items,
        grades: fixture.grades,
        grading_scheme: [
          {"A", "93.0"},
          {"A-", "90.0"},
          {"B+", "87.0"},
          {"B", "83.0"},
          {"B-", "80.0"},
          {"C", "70.0"},
          {"F", "0.0"}
        ]
      ],
      extra
    )
  end

  defp assignment(id, course, group, title, points_possible),
    do:
      Assignment.new!(%{
        id: id,
        course_id: course.id,
        assignment_group_id: group.id,
        title: title,
        points_possible: points_possible,
        status: :published
      })

  defp grade_item(assignment),
    do:
      GradeItem.new!(%{
        id: "grade-item-#{assignment.id}",
        course_id: assignment.course_id,
        assignment_id: assignment.id,
        assignment_group_id: assignment.assignment_group_id,
        title: assignment.title,
        points_possible: assignment.points_possible
      })

  defp grade(id, assignment, student, points, extra \\ []) do
    Grade.new!(%{
      id: id,
      grade_item_id: "grade-item-#{assignment.id}",
      submission_id: "submission-#{assignment.id}",
      student_user_id: student.id,
      grader_user_id: "teacher-1",
      points: points,
      state: Keyword.get(extra, :state, :posted),
      posted_at: Keyword.get(extra, :posted_at, ~U[2027-01-13 12:00:00Z]),
      grading_comments: Keyword.get(extra, :grading_comments, [])
    })
  end

  defp find_assignment(view, assignment_id),
    do: view.groups |> Enum.flat_map(& &1.assignments) |> Enum.find(&(&1.id == assignment_id))
end
