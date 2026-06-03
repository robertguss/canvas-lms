defmodule WtsLms.Sis.DryRunTest do
  use ExUnit.Case, async: true

  alias WtsLms.Sis.DryRun
  alias WtsLms.Schema.{Enrollment, Role, User}

  @fixture Path.expand("../../fixtures/sis/add_drop.csv", __DIR__)

  test "dry-run reports add drop idempotency update and conflicts without mutating state" do
    student =
      Role.new!(%{id: "role-student", name: "Student", kind: :student, account_id: "acct-1"})

    unchanged_user =
      User.new!(%{
        id: "user-unchanged",
        sis_user_id: "sis-unchanged",
        display_name: "Unchanged User",
        email: "unchanged@example.edu",
        role_ids: [student.id],
        status: :active,
        source_updated_at: ~U[2026-06-02 00:00:00Z]
      })

    updated_user =
      User.new!(%{
        id: "user-updated",
        sis_user_id: "sis-updated",
        display_name: "Updated User",
        email: "old-updated@example.edu",
        role_ids: [student.id],
        status: :active,
        source_updated_at: ~U[2026-06-01 00:00:00Z]
      })

    dropped_user =
      User.new!(%{
        id: "user-dropped",
        sis_user_id: "sis-dropped",
        display_name: "Dropped User",
        email: "dropped@example.edu",
        role_ids: [student.id],
        status: :active
      })

    dropped_enrollment =
      Enrollment.new!(%{
        id: "enrollment-drop",
        user_id: dropped_user.id,
        section_id: "sec-1",
        course_id: "course-1",
        role_id: student.id,
        state: :active,
        owner_system: :sis
      })

    existing = %{
      users: [unchanged_user, updated_user, dropped_user],
      roles: [student],
      enrollments: [dropped_enrollment]
    }

    assert {:ok, report} = DryRun.run_file(@fixture, existing: existing)

    assert report.counts.inserted == 0
    assert report.counts.updated == 1
    assert report.counts.unchanged == 1
    assert report.counts.dropped == 1
    assert report.counts.conflicted == 3
    assert report.persisted? == false
    assert Enum.any?(report.rows, &(&1.reason == "unsupported role"))

    duplicate_rows =
      Enum.filter(
        report.rows,
        &(&1.source_key == "sis-new" && &1.reason == "duplicate user key in extract")
      )

    assert length(duplicate_rows) == 2
    assert Enum.all?(duplicate_rows, &(&1.action == :conflicted))

    assert updated_user.email == "old-updated@example.edu"
    assert dropped_enrollment.state == :active
  end
end
