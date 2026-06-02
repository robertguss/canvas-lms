defmodule WtsLmsWeb.AuthControllerTest do
  use ExUnit.Case, async: true

  alias WtsLms.Schema.{Enrollment, Role, User}
  alias WtsLmsWeb.AuthController

  test "SAML callback creates an application session for a valid Populi assertion" do
    role = Role.new!(%{id: "role-teacher", name: "Teacher", kind: :teacher, account_id: "acct-1"})

    user =
      User.new!(%{
        id: "user-1",
        sis_user_id: "sis-1",
        display_name: "Teacher",
        email: "teacher@example.edu",
        role_ids: [role.id],
        status: :active
      })

    enrollment =
      Enrollment.new!(%{
        id: "enrollment-1",
        user_id: user.id,
        role_id: role.id,
        course_id: "course-1",
        section_id: "section-1",
        state: :active,
        owner_system: :sis
      })

    assertion = %{
      "NameID" => "populi-teacher",
      "email" => "teacher@example.edu",
      "sis_user_id" => "sis-1",
      "first_name" => "Teacher",
      "last_name" => "One"
    }

    assert %{status: 201, session: session, audit: %{reason_code: "valid assertion"}} =
             AuthController.saml_callback(%{"SAMLResponse" => assertion},
               users: [user],
               roles: [role],
               enrollments: [enrollment],
               validation: :contract_valid
             )

    assert session.user_id == user.id
    assert session.idle_timeout_seconds == 28_800
    assert session.absolute_timeout_seconds == 43_200
  end
end
