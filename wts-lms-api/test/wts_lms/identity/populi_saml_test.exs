defmodule WtsLms.Identity.PopuliSamlTest do
  use ExUnit.Case, async: true

  alias WtsLms.Identity.PopuliSaml
  alias WtsLms.Schema.{Enrollment, Role, User}

  test "valid Populi assertion maps only to existing active SIS user with supported role" do
    role = Role.new!(%{id: "role-student", name: "Student", kind: :student, account_id: "acct-1"})

    user =
      User.new!(%{
        id: "user-1",
        sis_user_id: "sis-100",
        display_name: "Student One",
        email: "student@example.edu",
        role_ids: [role.id],
        status: :active,
        saml_name_id: nil
      })

    enrollment =
      Enrollment.new!(%{
        id: "enrollment-1",
        course_id: "course-1",
        section_id: "section-1",
        user_id: user.id,
        role_id: role.id,
        state: :active,
        owner_system: :sis
      })

    assertion = %{
      "NameID" => "populi-login-100",
      "email" => " Student@Example.EDU ",
      "sis_user_id" => "sis-100",
      "first_name" => "Student",
      "last_name" => "One"
    }

    assert {:ok, result} =
             PopuliSaml.accept(assertion,
               users: [user],
               roles: [role],
               enrollments: [enrollment],
               validation: :contract_valid
             )

    assert result.user.id == user.id
    assert result.updated_user.saml_name_id == "populi-login-100"
    assert result.normalized_email == "student@example.edu"
    assert result.session.idle_timeout_seconds == 8 * 60 * 60
    assert result.session.absolute_timeout_seconds == 12 * 60 * 60
    assert result.audit.reason_code == "valid assertion"
  end

  test "missing attributes are rejected before lookup without revealing user existence" do
    assert {:error, result} =
             PopuliSaml.accept(%{"email" => "student@example.edu", "sis_user_id" => "sis-100"},
               users: [],
               roles: [],
               enrollments: [],
               validation: :contract_valid
             )

    assert result.audit.reason_code == "missing attribute"
    assert result.audit.attributes == ["NameID"]
    refute Map.has_key?(result, :user)
  end

  test "disabled, unmatched, conflicting, and unsupported role assertions are rejected" do
    student_role =
      Role.new!(%{id: "role-student", name: "Student", kind: :student, account_id: "acct-1"})

    observer_role =
      Role.new!(%{id: "role-observer", name: "Observer", kind: :observer, account_id: "acct-1"})

    active_user =
      User.new!(%{
        id: "user-1",
        sis_user_id: "sis-100",
        display_name: "Student One",
        email: "student@example.edu",
        role_ids: [student_role.id],
        status: :active,
        saml_name_id: "bound-name-id"
      })

    disabled_user =
      User.new!(%{
        id: "user-2",
        sis_user_id: "sis-200",
        display_name: "Disabled One",
        email: "disabled@example.edu",
        role_ids: [student_role.id],
        status: :disabled
      })

    unsupported_user =
      User.new!(%{
        id: "user-3",
        sis_user_id: "sis-300",
        display_name: "Observer One",
        email: "observer@example.edu",
        role_ids: [observer_role.id],
        status: :active
      })

    active_enrollment = enrollment_for(active_user, student_role)
    disabled_enrollment = enrollment_for(disabled_user, student_role)
    unsupported_enrollment = enrollment_for(unsupported_user, observer_role)
    users = [active_user, disabled_user, unsupported_user]
    roles = [student_role, observer_role]

    assert {:error, %{audit: %{reason_code: "unmatched user"}}} =
             PopuliSaml.accept(assertion("sis-404", "nobody@example.edu", "missing-name-id"),
               users: users,
               roles: roles,
               enrollments: [active_enrollment, disabled_enrollment, unsupported_enrollment],
               validation: :contract_valid
             )

    assert {:error, %{audit: %{reason_code: "disabled user", sis_user_id: "sis-200"}}} =
             PopuliSaml.accept(assertion("sis-200", "disabled@example.edu", "disabled-name-id"),
               users: users,
               roles: roles,
               enrollments: [active_enrollment, disabled_enrollment, unsupported_enrollment],
               validation: :contract_valid
             )

    assert {:error, %{audit: %{reason_code: "identity conflict"}}} =
             PopuliSaml.accept(assertion("sis-100", "student@example.edu", "different-name-id"),
               users: users,
               roles: roles,
               enrollments: [active_enrollment, disabled_enrollment, unsupported_enrollment],
               validation: :contract_valid
             )

    assert {:error, %{audit: %{reason_code: "unsupported role", roles: ["Observer"]}}} =
             PopuliSaml.accept(assertion("sis-300", "observer@example.edu", "observer-name-id"),
               users: users,
               roles: roles,
               enrollments: [active_enrollment, disabled_enrollment, unsupported_enrollment],
               validation: :contract_valid
             )
  end

  defp assertion(sis_user_id, email, name_id) do
    %{
      "NameID" => name_id,
      "email" => email,
      "sis_user_id" => sis_user_id,
      "first_name" => "Test",
      "last_name" => "User"
    }
  end

  defp enrollment_for(user, role) do
    Enrollment.new!(%{
      id: "enrollment-#{user.id}",
      course_id: "course-1",
      section_id: "section-1",
      user_id: user.id,
      role_id: role.id,
      state: :active,
      owner_system: :sis
    })
  end
end
