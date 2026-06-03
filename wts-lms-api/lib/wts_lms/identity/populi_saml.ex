defmodule WtsLms.Identity.PopuliSaml do
  @moduledoc """
  Contract-level Populi SAML assertion acceptance for SIS-synced users.
  """

  alias WtsLms.Authorization.RoleAuthorization

  @required_attributes [{"NameID", :name_id}, {"email", :email}, {"sis_user_id", :sis_user_id}]
  @idle_timeout_seconds 8 * 60 * 60
  @absolute_timeout_seconds 12 * 60 * 60

  def accept(assertion, opts \\ []) when is_map(assertion) do
    with :ok <- validate_contract(assertion, opts),
         {:ok, attrs} <- required_attributes(assertion),
         {:ok, user} <- match_user(attrs, Keyword.get(opts, :users, [])),
         :ok <- verify_email(user, attrs),
         :ok <- verify_name_id(user, attrs),
         {:ok, authorization} <-
           RoleAuthorization.authorize(user,
             roles: Keyword.get(opts, :roles, []),
             enrollments: Keyword.get(opts, :enrollments, [])
           ) do
      updated_user = %{user | saml_name_id: value(user, :saml_name_id) || attrs.name_id}

      {:ok,
       %{
         user: user,
         updated_user: updated_user,
         authorization: authorization,
         normalized_email: attrs.email,
         session: session_for(user),
         audit: audit("valid assertion", attrs)
       }}
    else
      {:error, %{reason_code: _reason} = error} -> {:error, %{audit: error}}
      {:error, %{audit: _audit} = result} -> {:error, result}
    end
  end

  defp validate_contract(_assertion, opts) do
    case Keyword.get(opts, :validation, :contract_valid) do
      :contract_valid -> :ok
      :invalid_signature -> {:error, %{reason_code: "invalid signature"}}
      :invalid_audience -> {:error, %{reason_code: "invalid audience"}}
      :expired_assertion -> {:error, %{reason_code: "expired assertion"}}
    end
  end

  defp required_attributes(assertion) do
    missing =
      @required_attributes
      |> Enum.map(fn {source, _target} -> source end)
      |> Enum.filter(&blank?(Map.get(assertion, &1)))

    if missing == [] do
      {:ok,
       %{
         name_id: assertion |> Map.fetch!("NameID") |> String.trim(),
         email: assertion |> Map.fetch!("email") |> normalize_email(),
         sis_user_id: assertion |> Map.fetch!("sis_user_id") |> String.trim()
       }}
    else
      {:error, %{audit: %{reason_code: "missing attribute", attributes: missing}}}
    end
  end

  defp match_user(attrs, users) do
    matches = Enum.filter(users, &(value(&1, :sis_user_id) == attrs.sis_user_id))

    case matches do
      [user] ->
        if RoleAuthorization.disabled?(user) do
          {:error,
           %{
             reason_code: "disabled user",
             sis_user_id: attrs.sis_user_id,
             status: value(user, :status)
           }}
        else
          {:ok, user}
        end

      [] ->
        {:error, %{reason_code: "unmatched user", sis_user_id: attrs.sis_user_id}}

      _many ->
        {:error, %{reason_code: "identity conflict", sis_user_id: attrs.sis_user_id}}
    end
  end

  defp verify_email(user, attrs) do
    if normalize_email(value(user, :email)) == attrs.email do
      :ok
    else
      {:error,
       %{reason_code: "identity conflict", sis_user_id: attrs.sis_user_id, email: attrs.email}}
    end
  end

  defp verify_name_id(user, attrs) do
    case value(user, :saml_name_id) do
      nil -> :ok
      "" -> :ok
      bound when bound == attrs.name_id -> :ok
      _other -> {:error, %{reason_code: "identity conflict", sis_user_id: attrs.sis_user_id}}
    end
  end

  defp session_for(user) do
    %{
      user_id: value(user, :id),
      idle_timeout_seconds: @idle_timeout_seconds,
      absolute_timeout_seconds: @absolute_timeout_seconds
    }
  end

  defp audit(reason, attrs) do
    %{reason_code: reason, sis_user_id: attrs.sis_user_id, normalized_email: attrs.email}
  end

  defp normalize_email(value), do: value |> to_string() |> String.trim() |> String.downcase()
  defp blank?(value), do: value in [nil, ""] || (is_binary(value) && String.trim(value) == "")
  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
