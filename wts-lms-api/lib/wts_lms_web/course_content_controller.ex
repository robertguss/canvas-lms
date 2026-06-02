defmodule WtsLmsWeb.CourseContentController do
  @moduledoc """
  Thin Phoenix-compatible controller surface for course content responses.
  """

  alias WtsLms.CourseContent

  def show(params, current_user, opts \\ [])

  def show(%{"course_id" => course_id}, current_user, opts) do
    case CourseContent.get_course_content(course_id, current_user, opts) do
      {:ok, content} ->
        %{status: 200, data: content}

      {:error, %{status: 403, reason_code: reason_code}} ->
        %{status: 403, error: %{reason_code: reason_code}}
    end
  end

  def show(%{course_id: course_id}, current_user, opts) do
    show(%{"course_id" => course_id}, current_user, opts)
  end
end
