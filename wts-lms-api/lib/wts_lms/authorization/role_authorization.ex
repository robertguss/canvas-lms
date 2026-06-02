defmodule WtsLms.Authorization.RoleAuthorization do
  @moduledoc """
  Authorization checks derived from current SIS-owned user, role, and enrollment state.
  """

  @supported_roles ["Admin", "Student", "Teacher"]
  @blocked_statuses [:disabled, :inactive, :blocked, "disabled", "inactive", "blocked"]
  @active_states [:active, "active"]

  def supported_roles, do: @supported_roles

  def authorize(user, opts \\ []) do
    roles = Keyword.get(opts, :roles, [])
    enrollments = Keyword.get(opts, :enrollments, [])

    cond do
      disabled?(user) ->
        {:error, %{reason_code: "disabled user", sis_user_id: value(user, :sis_user_id)}}

      true ->
        role_names = current_role_names(user, roles, enrollments)
        unsupported = role_names -- @supported_roles
        supported = role_names -- unsupported

        cond do
          unsupported != [] -> {:error, %{reason_code: "unsupported role", roles: unsupported}}
          supported == [] -> {:error, %{reason_code: "unsupported role", roles: []}}
          true -> {:ok, %{roles: Enum.sort(supported)}}
        end
    end
  end

  def disabled?(user) do
    value(user, :disabled) == true || value(user, :status) in @blocked_statuses
  end

  def current_role_names(user, roles, enrollments) do
    role_by_id = Map.new(roles, &{value(&1, :id), &1})

    direct_role_ids = value(user, :role_ids) || []

    enrollment_role_ids =
      enrollments
      |> Enum.filter(
        &(value(&1, :user_id) == value(user, :id) && value(&1, :state) in @active_states)
      )
      |> Enum.map(&value(&1, :role_id))

    (direct_role_ids ++ enrollment_role_ids)
    |> Enum.uniq()
    |> Enum.map(&Map.get(role_by_id, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&role_name/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp role_name(role) do
    case value(role, :kind) do
      :admin -> "Admin"
      "admin" -> "Admin"
      :student -> "Student"
      "student" -> "Student"
      :teacher -> "Teacher"
      "teacher" -> "Teacher"
      _other -> to_string(value(role, :name))
    end
  end

  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
