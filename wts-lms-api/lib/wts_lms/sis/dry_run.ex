defmodule WtsLms.Sis.DryRun do
  @moduledoc """
  Deterministic SIS feed dry-run validation without persistent mutations.
  """

  alias WtsLms.Authorization.RoleAuthorization

  @zero_counts %{
    inserted: 0,
    updated: 0,
    unchanged: 0,
    dropped: 0,
    disabled: 0,
    skipped: 0,
    conflicted: 0,
    failed: 0
  }

  def run_file(path, opts \\ []) do
    path
    |> File.read()
    |> case do
      {:ok, content} -> run(content, opts)
      {:error, reason} -> {:error, %{reason_code: "failed", detail: :file.format_error(reason)}}
    end
  end

  def run(content, opts \\ []) when is_binary(content) do
    existing = Keyword.get(opts, :existing, %{users: [], roles: [], enrollments: []})

    with {:ok, rows} <- parse_csv(content) do
      report_rows = classify_rows(rows, existing)

      {:ok,
       %{mode: :dry_run, persisted?: false, counts: count_rows(report_rows), rows: report_rows}}
    end
  end

  def format_report(report) do
    counts = report.counts

    [
      "mode=dry-run persisted=#{report.persisted?}",
      "inserted=#{counts.inserted}",
      "updated=#{counts.updated}",
      "unchanged=#{counts.unchanged}",
      "dropped=#{counts.dropped}",
      "disabled=#{counts.disabled}",
      "skipped=#{counts.skipped}",
      "conflicted=#{counts.conflicted}",
      "failed=#{counts.failed}"
    ]
    |> Enum.join(" ")
  end

  defp parse_csv(content) do
    lines = content |> String.split(~r/\R/, trim: true)

    case lines do
      [] ->
        {:error, %{reason_code: "failed", detail: :empty_file}}

      [header | rows] ->
        headers = split_line(header)

        {:ok,
         rows
         |> Enum.with_index(2)
         |> Enum.map(fn {line, number} ->
           values = split_line(line)
           %{line: number, data: headers |> Enum.zip(values) |> Map.new()}
         end)}
    end
  end

  defp classify_rows(rows, existing) do
    duplicate_lines = duplicate_lines(rows, "sis_user_id")
    existing_users = Map.get(existing, :users, [])
    existing_enrollments = Map.get(existing, :enrollments, [])
    user_by_sis_id = Map.new(existing_users, &{value(&1, :sis_user_id), &1})

    Enum.map(rows, fn row ->
      data = row.data
      sis_user_id = data["sis_user_id"]
      role = data["role"]

      cond do
        row.line in duplicate_lines ->
          outcome(row, sis_user_id, :conflicted, "duplicate user key in extract")

        role not in RoleAuthorization.supported_roles() ->
          outcome(row, sis_user_id, :conflicted, "unsupported role")

        data["action"] == "drop" || data["enrollment_status"] == "dropped" ->
          classify_drop(row, user_by_sis_id, existing_enrollments)

        Map.get(user_by_sis_id, sis_user_id) == nil ->
          outcome(row, sis_user_id, :inserted, "new SIS user/enrollment")

        unchanged?(Map.fetch!(user_by_sis_id, sis_user_id), data) ->
          outcome(row, sis_user_id, :unchanged, "idempotent row")

        true ->
          outcome(row, sis_user_id, :updated, "newer SIS values")
      end
    end)
  end

  defp classify_drop(row, user_by_sis_id, enrollments) do
    user = Map.get(user_by_sis_id, row.data["sis_user_id"])

    if user &&
         Enum.any?(
           enrollments,
           &(value(&1, :user_id) == value(user, :id) && value(&1, :state) in [:active, "active"])
         ) do
      outcome(row, row.data["sis_user_id"], :dropped, "drop removes current access")
    else
      outcome(row, row.data["sis_user_id"], :unchanged, "drop already applied")
    end
  end

  defp unchanged?(user, data) do
    normalize_email(value(user, :email)) == normalize_email(data["email"]) &&
      value(user, :source_updated_at) == parse_timestamp(data["updated_at_source"])
  end

  defp count_rows(rows) do
    Enum.reduce(rows, @zero_counts, fn row, counts ->
      Map.update!(counts, row.action, &(&1 + 1))
    end)
  end

  defp duplicate_lines(rows, key) do
    rows
    |> Enum.reject(&blank?(&1.data[key]))
    |> Enum.group_by(& &1.data[key])
    |> Enum.flat_map(fn {_value, rows_for_key} ->
      if length(rows_for_key) > 1 do
        Enum.map(rows_for_key, & &1.line)
      else
        []
      end
    end)
    |> MapSet.new()
  end

  defp outcome(row, source_key, action, reason) do
    %{
      line: row.line,
      entity: row.data["entity"],
      source_key: source_key,
      action: action,
      outcome: action,
      reason: reason
    }
  end

  defp split_line(line), do: line |> String.split(",") |> Enum.map(&String.trim/1)

  defp parse_timestamp(value) do
    case DateTime.from_iso8601(value || "") do
      {:ok, datetime, _offset} -> DateTime.truncate(datetime, :second)
      _error -> nil
    end
  end

  defp normalize_email(value), do: value |> to_string() |> String.trim() |> String.downcase()
  defp blank?(value), do: value in [nil, ""] || (is_binary(value) && String.trim(value) == "")
  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
