defmodule WtsLms.CourseContent do
  @moduledoc """
  Course content access for enrolled WTS Student Teacher Admin users.
  """

  alias WtsLms.Authorization.RoleAuthorization

  @active_states [:active, "active"]
  @published_states [:published, "published", :active, "active", nil]

  def get_course_content(course_id, user, opts \\ []) do
    courses = Keyword.get(opts, :courses, [])
    enrollments = Keyword.get(opts, :enrollments, [])
    roles = Keyword.get(opts, :roles, [])

    with {:ok, course} <- find_course(course_id, courses),
         :ok <- authorize_course_user(course_id, user, roles, enrollments) do
      {:ok,
       %{
         course: course_payload(course),
         modules: module_payloads(course_id, opts),
         pages: page_payloads(course_id, opts),
         files: file_payloads(course_id, opts),
         announcements: announcement_payloads(course_id, opts),
         calendar_dates: calendar_payloads(course_id, opts)
       }}
    else
      {:error, error} -> {:error, Map.put_new(error, :content, nil)}
    end
  end

  defp find_course(course_id, courses) do
    case Enum.find(courses, &(value(&1, :id) == course_id)) do
      nil -> {:error, forbidden("course content forbidden")}
      course -> {:ok, course}
    end
  end

  defp authorize_course_user(course_id, user, roles, enrollments) do
    course_enrollments = Enum.filter(enrollments, &(value(&1, :course_id) == course_id))

    active_enrolled? =
      Enum.any?(course_enrollments, fn enrollment ->
        value(enrollment, :user_id) == value(user, :id) &&
          value(enrollment, :state) in @active_states
      end)

    if active_enrolled? do
      case RoleAuthorization.authorize(user, roles: roles, enrollments: course_enrollments) do
        {:ok, _authorization} ->
          :ok

        {:error, error} ->
          {:error, forbidden(Map.get(error, :reason_code, "course content forbidden"))}
      end
    else
      {:error, forbidden("course content forbidden")}
    end
  end

  defp forbidden(reason_code), do: %{status: 403, reason_code: reason_code}

  defp course_payload(course) do
    %{
      id: value(course, :id),
      name: value(course, :name),
      code: value(course, :code),
      syllabus_html: value(course, :syllabus_html)
    }
  end

  defp module_payloads(course_id, opts) do
    modules =
      opts
      |> Keyword.get(:modules, [])
      |> Enum.filter(&(value(&1, :course_id) == course_id && published?(&1)))
      |> Enum.sort_by(&(value(&1, :position) || 0))

    Enum.map(modules, fn module ->
      %{
        id: value(module, :id),
        title: value(module, :title),
        position: value(module, :position),
        pages: pages_for_module(course_id, value(module, :id), opts),
        files: files_for_course(course_id, opts)
      }
    end)
  end

  defp page_payloads(course_id, opts) do
    opts
    |> Keyword.get(:pages, [])
    |> Enum.filter(&(value(&1, :course_id) == course_id && published?(&1)))
    |> Enum.sort_by(&{value(&1, :module_id) || "", value(&1, :title) || ""})
    |> Enum.map(&page_payload/1)
  end

  defp pages_for_module(course_id, module_id, opts) do
    opts
    |> Keyword.get(:pages, [])
    |> Enum.filter(
      &(value(&1, :course_id) == course_id && value(&1, :module_id) == module_id && published?(&1))
    )
    |> Enum.sort_by(&(value(&1, :title) || ""))
    |> Enum.map(&page_payload/1)
  end

  defp page_payload(page) do
    %{
      id: value(page, :id),
      title: value(page, :title),
      slug: value(page, :slug),
      body_html: value(page, :body_html)
    }
  end

  defp file_payloads(course_id, opts), do: files_for_course(course_id, opts)

  defp files_for_course(course_id, opts) do
    opts
    |> Keyword.get(:files, [])
    |> Enum.filter(&(value(&1, :course_id) == course_id && course_visible_file?(&1)))
    |> Enum.sort_by(&(value(&1, :display_name) || ""))
    |> Enum.map(&file_payload/1)
  end

  defp file_payload(file) do
    %{
      id: value(file, :id),
      display_name: value(file, :display_name),
      content_type: value(file, :content_type),
      byte_size: value(file, :byte_size),
      checksum: value(file, :checksum)
    }
  end

  defp announcement_payloads(course_id, opts) do
    opts
    |> Keyword.get(:announcements, [])
    |> Enum.filter(&(value(&1, :course_id) == course_id && published?(&1)))
    |> Enum.sort_by(&(value(&1, :posted_at) || ""), :desc)
    |> Enum.map(fn announcement ->
      %{
        id: value(announcement, :id),
        title: value(announcement, :title),
        message_html: value(announcement, :message_html),
        posted_at: value(announcement, :posted_at)
      }
    end)
  end

  defp calendar_payloads(course_id, opts) do
    opts
    |> Keyword.get(:assignments, [])
    |> Enum.filter(&(value(&1, :course_id) == course_id && published?(&1)))
    |> Enum.sort_by(&(value(&1, :due_at) || ""))
    |> Enum.map(fn assignment ->
      %{
        assignment_id: value(assignment, :id),
        title: value(assignment, :title),
        due_at: value(assignment, :due_at),
        available_at: value(assignment, :available_at),
        lock_at: value(assignment, :lock_at)
      }
    end)
  end

  defp course_visible_file?(file), do: value(file, :visibility) in [:course, "course", nil]
  defp published?(entity), do: value(entity, :status) in @published_states

  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
