defmodule WtsLmsWeb.AuthController do
  @moduledoc """
  Minimal Phoenix-compatible auth controller surface for SAML callback tests.
  """

  alias WtsLms.Identity.PopuliSaml

  def saml_callback(%{"SAMLResponse" => assertion}, opts \\ []) do
    case PopuliSaml.accept(assertion, opts) do
      {:ok, result} ->
        %{status: 201, session: result.session, user: result.user, audit: result.audit}

      {:error, %{audit: %{reason_code: "missing attribute"} = audit}} ->
        %{status: 400, audit: audit}

      {:error, %{audit: %{reason_code: "unmatched user"} = audit}} ->
        %{status: 403, audit: audit}

      {:error, %{audit: audit}} ->
        %{status: 403, audit: audit}
    end
  end
end
