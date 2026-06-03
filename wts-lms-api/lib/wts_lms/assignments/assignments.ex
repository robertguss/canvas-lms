defmodule WtsLms.Assignments do
  @moduledoc """
  Assignment submission handling for WTS text, file-upload, and no-submission coursework.
  """

  alias WtsLms.Authorization.RoleAuthorization
  alias WtsLms.Files
  alias WtsLms.Schema.Submission

  @active_states [:active, "active"]
  @supported_submission_types [:text_entry, :file_upload, :none, :no_submission]

  def submit_assignment(assignment_id, user, attrs, opts \\ []) do
    with {:ok, assignment} <- find_assignment(assignment_id, Keyword.get(opts, :assignments, [])),
         {:ok, enrollment} <- authorize_assignment_user(assignment, user, opts),
         {:ok, submission_type} <- submission_type(assignment) do
      build_submission(submission_type, assignment, enrollment, user, attrs, opts)
    end
  end

  def add_comment(submission_id, author, attrs, opts \\ []) do
    with {:ok, submission} <- find_submission(submission_id, Keyword.get(opts, :submissions, [])),
         {:ok, assignment} <-
           find_assignment(value(submission, :assignment_id), Keyword.get(opts, :assignments, [])),
         {:ok, _enrollment} <- authorize_assignment_user(assignment, author, opts),
         {:ok, body} <- comment_body(attrs) do
      comment = %{
        id: "comment-#{length(value(submission, :comments) || []) + 1}",
        author_user_id: value(author, :id),
        author_display_name: value(author, :display_name),
        body: body,
        created_at: now(opts),
        redaction_boundary: %{
          redactable_fields: [:body],
          retained_fields: [:id, :author_user_id, :created_at]
        }
      }

      {:ok,
       %{
         submission
         | comments: (value(submission, :comments) || []) ++ [comment],
           updated_at: now(opts)
       }}
    end
  end

  defp build_submission(:text_entry, assignment, enrollment, user, attrs, opts) do
    with {:ok, body_html} <- required_body(attrs) do
      submission =
        base_submission(assignment, enrollment, user, opts)
        |> Map.put(:state, :submitted)
        |> Map.put(:body_html, body_html)

      {:ok, %{submission: struct(Submission, submission), attachments: []}}
    end
  end

  defp build_submission(:file_upload, assignment, enrollment, user, attrs, opts) do
    attachments = value(attrs, :attachments) || []

    cond do
      attachments == [] ->
        {:error, %{status: 422, reason_code: "missing attachment metadata"}}

      true ->
        with {:ok, files} <- sanitize_attachments(assignment, user, attachments, opts) do
          submission_id = submission_id(assignment, user, opts)

          files = Enum.map(files, &%{&1 | submission_id: submission_id})

          submission =
            base_submission(assignment, enrollment, user, opts)
            |> Map.put(:id, submission_id)
            |> Map.put(:state, :submitted)
            |> Map.put(:attachment_file_ids, Enum.map(files, & &1.id))

          {:ok, %{submission: struct(Submission, submission), attachments: files}}
        end
    end
  end

  defp build_submission(submission_type, assignment, enrollment, user, attrs, opts)
       when submission_type in [:none, :no_submission] do
    if payload_present?(attrs) do
      {:error, %{status: 422, reason_code: "payload not allowed"}}
    else
      submission =
        base_submission(assignment, enrollment, user, opts)
        |> Map.put(:state, :acknowledged)

      {:ok, %{submission: struct(Submission, submission), attachments: []}}
    end
  end

  defp sanitize_attachments(assignment, user, attachments, opts) do
    attachments
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {attachment, index}, {:ok, files} ->
      case Files.sanitize_attachment_metadata(assignment, user, attachment, index, opts) do
        {:ok, file} -> {:cont, {:ok, files ++ [file]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp base_submission(assignment, enrollment, user, opts) do
    %Submission{
      id: submission_id(assignment, user, opts),
      assignment_id: value(assignment, :id),
      user_id: value(user, :id),
      enrollment_id: value(enrollment, :id),
      attempt: next_attempt(assignment, user, opts),
      state: :submitted,
      body_html: nil,
      attachment_file_ids: [],
      submitted_at: now(opts),
      comments: [],
      inserted_at: now(opts),
      updated_at: now(opts),
      source_system: :canvas
    }
    |> Map.from_struct()
  end

  defp submission_id(assignment, user, opts) do
    "submission-#{value(assignment, :id)}-#{value(user, :id)}-#{next_attempt(assignment, user, opts)}"
  end

  defp next_attempt(assignment, user, opts) do
    existing =
      opts
      |> Keyword.get(:submissions, [])
      |> Enum.filter(
        &(value(&1, :assignment_id) == value(assignment, :id) &&
            value(&1, :user_id) == value(user, :id))
      )

    case Enum.map(existing, &(value(&1, :attempt) || 0)) do
      [] -> 1
      attempts -> Enum.max(attempts) + 1
    end
  end

  defp find_assignment(assignment_id, assignments) do
    case Enum.find(assignments, &(value(&1, :id) == assignment_id)) do
      nil -> {:error, %{status: 404, reason_code: "assignment missing"}}
      assignment -> {:ok, assignment}
    end
  end

  defp find_submission(submission_id, submissions) do
    case Enum.find(submissions, &(value(&1, :id) == submission_id)) do
      nil -> {:error, %{status: 404, reason_code: "submission missing"}}
      submission -> {:ok, submission}
    end
  end

  defp authorize_assignment_user(assignment, user, opts) do
    course_id = value(assignment, :course_id)
    enrollments = Keyword.get(opts, :enrollments, [])
    roles = Keyword.get(opts, :roles, [])
    course_enrollments = Enum.filter(enrollments, &(value(&1, :course_id) == course_id))

    enrollment =
      Enum.find(course_enrollments, fn enrollment ->
        value(enrollment, :user_id) == value(user, :id) &&
          value(enrollment, :state) in @active_states
      end)

    if enrollment do
      case RoleAuthorization.authorize(user, roles: roles, enrollments: course_enrollments) do
        {:ok, _authorization} -> {:ok, enrollment}
        {:error, _error} -> {:error, forbidden()}
      end
    else
      {:error, forbidden()}
    end
  end

  defp forbidden, do: %{status: 403, reason_code: "assignment submission forbidden"}

  defp submission_type(assignment) do
    types =
      assignment
      |> value(:submission_types)
      |> List.wrap()
      |> Enum.map(&normalize_submission_type/1)

    unsupported = types -- @supported_submission_types

    cond do
      unsupported != [] -> {:error, %{status: 422, reason_code: "unsupported submission type"}}
      :text_entry in types -> {:ok, :text_entry}
      :file_upload in types -> {:ok, :file_upload}
      :none in types -> {:ok, :none}
      :no_submission in types -> {:ok, :no_submission}
      true -> {:error, %{status: 422, reason_code: "unsupported submission type"}}
    end
  end

  defp normalize_submission_type("text_entry"), do: :text_entry
  defp normalize_submission_type("file_upload"), do: :file_upload
  defp normalize_submission_type("none"), do: :none
  defp normalize_submission_type("no_submission"), do: :no_submission
  defp normalize_submission_type(value), do: value

  defp required_body(attrs) do
    case value(attrs, :body_html) do
      body when is_binary(body) ->
        if String.trim(body) == "" do
          {:error, %{status: 422, reason_code: "missing text entry body"}}
        else
          {:ok, body}
        end

      _other ->
        {:error, %{status: 422, reason_code: "missing text entry body"}}
    end
  end

  defp comment_body(attrs) do
    case value(attrs, :body) do
      body when is_binary(body) ->
        if String.trim(body) == "" do
          {:error, %{status: 422, reason_code: "missing comment body"}}
        else
          {:ok, body}
        end

      _other ->
        {:error, %{status: 422, reason_code: "missing comment body"}}
    end
  end

  defp payload_present?(attrs) do
    not blank?(value(attrs, :body_html)) || (value(attrs, :attachments) || []) != []
  end

  defp now(opts), do: Keyword.get(opts, :now) || DateTime.utc_now() |> DateTime.truncate(:second)
  defp blank?(value), do: value in [nil, ""] || (is_binary(value) && String.trim(value) == "")
  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
