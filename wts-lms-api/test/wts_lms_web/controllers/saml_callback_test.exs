defmodule WtsLmsWeb.SamlCallbackTest do
  use ExUnit.Case, async: true

  alias WtsLms.Schema.{Role, User}
  alias WtsLmsWeb.AuthController

  test "SAML callback rejects disabled SIS users without creating a session" do
    role = Role.new!(%{id: "role-student", name: "Student", kind: :student, account_id: "acct-1"})

    user =
      User.new!(%{
        id: "user-disabled",
        sis_user_id: "sis-disabled",
        display_name: "Disabled",
        email: "disabled@example.edu",
        role_ids: [role.id],
        status: :disabled
      })

    assertion = %{
      "NameID" => "populi-disabled",
      "email" => "disabled@example.edu",
      "sis_user_id" => "sis-disabled",
      "first_name" => "Disabled",
      "last_name" => "User"
    }

    assert %{status: 403, audit: %{reason_code: "disabled user"}} =
             AuthController.saml_callback(%{"SAMLResponse" => assertion},
               users: [user],
               roles: [role],
               enrollments: [],
               validation: :contract_valid
             )
  end
end
