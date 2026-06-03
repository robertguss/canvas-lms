defmodule WtsLms.Notifications do
  @moduledoc """
  Dependency-light notification event helpers for WTS coursework events.
  """

  alias WtsLms.Notifications.{EmailDelivery, Event, Notification}
  alias WtsLms.Workers.EmailDeliveryWorker

  @active_states [:active, "active"]
  @supported_channels [:in_app, :email]

  def supported_channels, do: @supported_channels

  def announcement_published(announcement, opts \\ []) do
    announcement_event(:announcement_published, announcement, opts)
  end

  def announcement_updated(announcement, opts \\ []) do
    announcement_event(:announcement_updated, announcement, opts)
  end

  def due_date_changed(assignment, old_due_at, new_due_at, opts \\ []) do
    event = %Event{
      id:
        "event-due-date-changed-#{value(assignment, :id)}-#{id_part(old_due_at)}-#{id_part(new_due_at)}",
      type: :due_date_changed,
      course_id: value(assignment, :course_id),
      subject_id: value(assignment, :id),
      title: "Due date changed: #{value(assignment, :title)}",
      body:
        "The due date for #{value(assignment, :title)} changed from #{old_due_at} to #{new_due_at}.",
      metadata: %{
        assignment_id: value(assignment, :id),
        old_due_at: old_due_at,
        new_due_at: new_due_at
      },
      created_at: now(opts)
    }

    {:ok, deliver_to_enrolled(event, opts)}
  end

  def submission_comment_added(submission, comment, opts \\ []) do
    with {:ok, assignment} <-
           find_one(
             Keyword.get(opts, :assignments, []),
             value(submission, :assignment_id),
             "assignment missing"
           ),
         {:ok, recipient} <-
           find_one(
             Keyword.get(opts, :users, []),
             value(submission, :user_id),
             "recipient missing"
           ) do
      event = %Event{
        id: "event-submission-comment-added-#{value(submission, :id)}-#{value(comment, :id)}",
        type: :submission_comment_added,
        course_id: value(assignment, :course_id),
        subject_id: value(submission, :id),
        title: "New comment: #{value(assignment, :title)}",
        body: "A new comment was added to #{value(assignment, :title)}.",
        metadata: %{
          assignment_id: value(assignment, :id),
          submission_id: value(submission, :id),
          comment_id: value(comment, :id)
        },
        created_at: now(opts)
      }

      {:ok, deliver_to_recipients(event, [recipient], opts)}
    end
  end

  def grade_released(grade, opts \\ []) do
    with {:ok, grade_item} <-
           find_one(
             Keyword.get(opts, :grade_items, []),
             value(grade, :grade_item_id),
             "grade item missing"
           ),
         {:ok, assignment} <-
           find_one(
             Keyword.get(opts, :assignments, []),
             value(grade_item, :assignment_id),
             "assignment missing"
           ),
         {:ok, recipient} <-
           find_one(
             Keyword.get(opts, :users, []),
             value(grade, :student_user_id),
             "recipient missing"
           ) do
      event = %Event{
        id: "event-grade-released-#{value(grade, :id)}",
        type: :grade_released,
        course_id: value(assignment, :course_id),
        subject_id: value(grade, :id),
        title: "Grade released: #{value(assignment, :title)}",
        body: "A grade for #{value(assignment, :title)} is available.",
        metadata: %{assignment_id: value(assignment, :id), grade_id: value(grade, :id)},
        created_at: now(opts)
      }

      {:ok, deliver_to_recipients(event, [recipient], opts)}
    end
  end

  defp announcement_event(type, announcement, opts) do
    title = value(announcement, :title)
    label = if type == :announcement_updated, do: "Announcement updated", else: "New announcement"

    event = %Event{
      id: "event-#{type_slug(type)}-#{value(announcement, :id)}",
      type: type,
      course_id: value(announcement, :course_id),
      subject_id: value(announcement, :id),
      title: "#{label}: #{title}",
      body: "#{title} is available in your course.",
      metadata: %{announcement_id: value(announcement, :id)},
      created_at: now(opts)
    }

    {:ok, deliver_to_enrolled(event, opts)}
  end

  defp deliver_to_enrolled(event, opts) do
    recipients = enrolled_recipients(event.course_id, opts)
    deliver_to_recipients(event, recipients, opts)
  end

  defp deliver_to_recipients(event, recipients, opts) do
    %{
      event: event,
      notifications: Enum.map(recipients, &notification_for(event, &1)),
      email_jobs: Enum.map(recipients, &email_job_for(event, &1, opts))
    }
  end

  defp enrolled_recipients(course_id, opts) do
    user_by_id = Map.new(Keyword.get(opts, :users, []), &{value(&1, :id), &1})

    opts
    |> Keyword.get(:enrollments, [])
    |> Enum.filter(&(value(&1, :course_id) == course_id && value(&1, :state) in @active_states))
    |> Enum.map(&Map.get(user_by_id, value(&1, :user_id)))
    |> Enum.reject(&is_nil/1)
  end

  defp notification_for(event, recipient) do
    %Notification{
      id: "notification-#{event.id}-#{value(recipient, :id)}",
      recipient_user_id: value(recipient, :id),
      course_id: event.course_id,
      event_type: event.type,
      title: event.title,
      body: event.body,
      metadata: event.metadata,
      read_at: nil,
      created_at: event.created_at
    }
  end

  defp email_job_for(event, recipient, opts) do
    recipient
    |> EmailDelivery.request(event, opts)
    |> EmailDeliveryWorker.new()
  end

  defp find_one(items, id, reason_code) do
    case Enum.find(items, &(value(&1, :id) == id)) do
      nil -> {:error, %{status: 404, reason_code: reason_code}}
      item -> {:ok, item}
    end
  end

  defp type_slug(type), do: type |> to_string() |> String.replace("_", "-")

  defp id_part(value),
    do: value |> to_string() |> String.replace(~r/[^A-Za-z0-9]/, "-") |> String.trim("-")

  defp now(opts), do: Keyword.get(opts, :now) || DateTime.utc_now() |> DateTime.truncate(:second)
  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
