defmodule WtsLms.Audit do
  @moduledoc """
  Pure audit event builders and admin-safe filtering for WTS coursework actions.
  """

  alias WtsLms.Audit.Event
  alias WtsLms.Security.SecureLog

  @safe_fields [
    :actor_id,
    :action,
    :target_type,
    :target_id,
    :course_id,
    :timestamp,
    :outcome,
    :reason_code,
    :metadata
  ]

  def login(attrs, opts \\ []), do: build(:login, :user, attrs, opts)
  def import_diff(attrs, opts \\ []), do: build(:import_diff, :import, attrs, opts)
  def grade_changed(attrs, opts \\ []), do: build(:grade_changed, :grade, attrs, opts)
  def grade_released(attrs, opts \\ []), do: build(:grade_released, :grade, attrs, opts)

  def submission_created(attrs, opts \\ []),
    do: build(:submission_created, :submission, attrs, opts)

  def submission_commented(attrs, opts \\ []),
    do: build(:submission_commented, :submission, attrs, opts)

  def file_authorized(attrs, opts \\ []) do
    action = value(attrs, :action) || :file_download_authorized
    build(action, :file, attrs, opts)
  end

  def list_admin_events(events, filters \\ []) do
    events
    |> Enum.map(&safe_event/1)
    |> Enum.filter(&matches_filters?(&1, filters))
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
  end

  def safe_event(%Event{} = event), do: event |> Map.from_struct() |> safe_event()

  def safe_event(event) when is_map(event) do
    event
    |> Map.take(@safe_fields)
    |> Map.update(:metadata, %{}, &safe_metadata/1)
  end

  defp build(action, target_type, attrs, opts) do
    {:ok,
     %Event{
       actor_id: value(attrs, :actor_id),
       action: action,
       target_type: target_type,
       target_id: value(attrs, :target_id),
       course_id: value(attrs, :course_id),
       timestamp: Keyword.get(opts, :now) || DateTime.utc_now() |> DateTime.truncate(:second),
       outcome: value(attrs, :outcome) || :ok,
       reason_code: value(attrs, :reason_code),
       metadata: safe_metadata(value(attrs, :metadata) || %{})
     }}
  end

  defp safe_metadata(metadata) do
    metadata
    |> SecureLog.sanitize()
    |> remove_redacted_values()
  end

  defp remove_redacted_values(metadata) when is_map(metadata) do
    metadata
    |> Enum.reject(fn {_key, item} -> item == SecureLog.redacted() end)
    |> Map.new(fn {key, item} -> {key, remove_redacted_values(item)} end)
  end

  defp remove_redacted_values(items) when is_list(items) do
    items
    |> Enum.reject(&(&1 == SecureLog.redacted()))
    |> Enum.map(&remove_redacted_values/1)
  end

  defp remove_redacted_values(value), do: value

  defp matches_filters?(event, filters) do
    Enum.all?(filters, fn {key, expected} -> Map.get(event, key) == expected end)
  end

  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
