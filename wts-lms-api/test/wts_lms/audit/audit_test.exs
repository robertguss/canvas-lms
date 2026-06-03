defmodule WtsLms.AuditTest do
  use ExUnit.Case, async: true

  alias WtsLms.Audit

  @now ~U[2026-06-03 18:00:00Z]

  test "grade change audit includes required context and excludes secrets" do
    {:ok, event} =
      Audit.grade_changed(
        %{
          actor_id: "teacher-1",
          target_id: "grade-1",
          course_id: "course-1",
          outcome: :ok,
          reason_code: "teacher grade save",
          metadata: %{
            grade_item_id: "grade-item-1",
            access_token: "secret-token",
            file_content: "draft contents",
            raw_url: "https://storage.example/private/file.pdf?token=abc"
          }
        },
        now: @now
      )

    assert event.actor_id == "teacher-1"
    assert event.action == :grade_changed
    assert event.target_type == :grade
    assert event.target_id == "grade-1"
    assert event.course_id == "course-1"
    assert event.timestamp == @now
    assert event.metadata == %{grade_item_id: "grade-item-1"}
    refute inspect(event) =~ "secret-token"
    refute inspect(event) =~ "draft contents"
    refute inspect(event) =~ "storage.example"
  end

  test "login import submission and file events sanitize sensitive inputs" do
    events = [
      Audit.login(%{
        actor_id: "student-1",
        target_id: "student-1",
        course_id: nil,
        outcome: :ok,
        reason_code: "valid assertion",
        metadata: %{saml_assertion: "SAML-PRIVATE-BLOB", authorization: "Bearer auth-token"}
      }),
      Audit.import_diff(%{
        actor_id: "admin-1",
        target_id: "import-1",
        course_id: "course-1",
        outcome: :ok,
        reason_code: "fixture diff",
        metadata: %{private_key: "key", inserted: 2, raw_url: "s3://bucket/object"}
      }),
      Audit.submission_created(%{
        actor_id: "student-1",
        target_id: "submission-1",
        course_id: "course-1",
        outcome: :ok,
        reason_code: "text entry submitted",
        metadata: %{body: "private submission body", assignment_id: "assignment-1"}
      }),
      Audit.file_authorized(%{
        actor_id: "student-1",
        action: :file_download_authorized,
        target_id: "file-1",
        course_id: "course-1",
        outcome: :ok,
        reason_code: "enrolled file access",
        metadata: %{
          object_url: "https://signed.example/file?token=abc",
          storage_key: "course/user/file.pdf",
          byte_size: 42
        }
      })
    ]

    for {:ok, event} <- events do
      inspected = inspect(event)

      refute inspected =~ "SAML-PRIVATE-BLOB"
      refute inspected =~ "auth-token"
      refute inspected =~ "private submission body"
      refute inspected =~ "signed.example"
      refute inspected =~ "s3://"
      refute inspected =~ "course/user/file.pdf"
    end

    assert {:ok, %{metadata: %{inserted: 2}}} = Enum.at(events, 1)
    assert {:ok, %{metadata: %{assignment_id: "assignment-1"}}} = Enum.at(events, 2)
    assert {:ok, %{metadata: %{byte_size: 42}}} = Enum.at(events, 3)
  end

  test "admin listing filters audit events and returns safe fields only" do
    {:ok, grade_event} =
      Audit.grade_released(
        %{
          actor_id: "teacher-1",
          target_id: "grade-1",
          course_id: "course-1",
          outcome: :ok,
          reason_code: "grade posted",
          metadata: %{points: "9", access_token: "secret"}
        },
        now: @now
      )

    {:ok, file_event} =
      Audit.file_authorized(
        %{
          actor_id: "student-1",
          action: :file_upload_authorized,
          target_id: "file-1",
          course_id: "course-2",
          outcome: :denied,
          reason_code: "file download forbidden",
          metadata: %{object_url: "https://signed.example/file", byte_size: 10}
        },
        now: DateTime.add(@now, 60, :second)
      )

    result = Audit.list_admin_events([grade_event, file_event], course_id: "course-1")

    assert [safe] = result

    assert Map.keys(safe) |> Enum.sort() ==
             [
               :action,
               :actor_id,
               :course_id,
               :metadata,
               :outcome,
               :reason_code,
               :target_id,
               :target_type,
               :timestamp
             ]

    assert safe.action == :grade_released
    assert safe.metadata == %{points: "9"}
    refute inspect(result) =~ "secret"
    refute inspect(result) =~ "signed.example"
  end
end
