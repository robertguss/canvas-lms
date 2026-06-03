defmodule WtsLms.Authorization.RoleAuthorizationTest do
  use ExUnit.Case, async: true

  alias WtsLms.Authorization.RoleAuthorization
  alias WtsLms.Schema.{Enrollment, Role, User}

  test "Student Teacher and Admin are the only roles authorized from current SIS state" do
    student =
      Role.new!(%{id: "role-student", name: "Student", kind: :student, account_id: "acct-1"})

    teacher =
      Role.new!(%{id: "role-teacher", name: "Teacher", kind: :teacher, account_id: "acct-1"})

    admin = Role.new!(%{id: "role-admin", name: "Admin", kind: :admin, account_id: "acct-1"})

    observer =
      Role.new!(%{id: "role-observer", name: "Observer", kind: :observer, account_id: "acct-1"})

    user =
      User.new!(%{
        id: "user-1",
        sis_user_id: "sis-1",
        display_name: "Active",
        email: "a@example.edu",
        role_ids: [student.id, teacher.id, admin.id],
        status: :active
      })

    observer_user =
      User.new!(%{
        id: "user-2",
        sis_user_id: "sis-2",
        display_name: "Observer",
        email: "o@example.edu",
        role_ids: [observer.id],
        status: :active
      })

    assert {:ok, %{roles: ["Admin", "Student", "Teacher"]}} =
             RoleAuthorization.authorize(user,
               roles: [student, teacher, admin, observer],
               enrollments: []
             )

    assert {:error, %{reason_code: "unsupported role", roles: ["Observer"]}} =
             RoleAuthorization.authorize(observer_user,
               roles: [student, teacher, admin, observer],
               enrollments: []
             )
  end

  test "disabled users and dropped enrollments are rejected on authorization checks" do
    student =
      Role.new!(%{id: "role-student", name: "Student", kind: :student, account_id: "acct-1"})

    disabled_user =
      User.new!(%{
        id: "user-1",
        sis_user_id: "sis-1",
        display_name: "Disabled",
        email: "d@example.edu",
        role_ids: [student.id],
        status: :disabled
      })

    dropped_user =
      User.new!(%{
        id: "user-2",
        sis_user_id: "sis-2",
        display_name: "Dropped",
        email: "drop@example.edu",
        role_ids: [],
        status: :active
      })

    dropped_enrollment =
      Enrollment.new!(%{
        id: "enrollment-1",
        user_id: dropped_user.id,
        role_id: student.id,
        course_id: "course-1",
        section_id: "section-1",
        state: :dropped,
        owner_system: :sis
      })

    assert {:error, %{reason_code: "disabled user"}} =
             RoleAuthorization.authorize(disabled_user, roles: [student], enrollments: [])

    assert {:error, %{reason_code: "unsupported role", roles: []}} =
             RoleAuthorization.authorize(dropped_user,
               roles: [student],
               enrollments: [dropped_enrollment]
             )
  end
end
