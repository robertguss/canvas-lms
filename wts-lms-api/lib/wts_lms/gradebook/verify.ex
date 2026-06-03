defmodule WtsLms.Gradebook.Verify do
  @moduledoc """
  Fixture verifier for deterministic gradebook calculation outputs.
  """

  alias WtsLms.Gradebook

  def run_file(path) do
    with {:ok, content} <- File.read(path),
         {:ok, fixture} <- decode(content),
         {:ok, report} <- run(fixture) do
      {:ok, report}
    else
      {:error, %{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error, %{reason_code: "gradebook fixture read failed", detail: reason}}
    end
  end

  def run(fixture) when is_map(fixture) do
    opts = [
      courses: fixture["courses"] || [],
      sections: fixture["sections"] || [],
      users: fixture["users"] || [],
      enrollments: fixture["enrollments"] || [],
      assignment_groups: fixture["assignment_groups"] || [],
      assignments: fixture["assignments"] || [],
      grade_items: fixture["grade_items"] || [],
      grades: fixture["grades"] || [],
      grading_scheme: scheme(fixture["grading_scheme"] || [])
    ]

    expected = fixture["expected"] || %{}

    with {:ok, view} <-
           Gradebook.teacher_view(fixture["course_id"], fixture["student_user_id"], opts) do
      actual = %{
        final_percentage: view.final_percentage,
        letter_display: view.letter_display
      }

      if actual.final_percentage == expected["final_percentage"] &&
           actual.letter_display == expected["letter_display"] do
        {:ok, actual}
      else
        {:error, %{reason_code: "gradebook fixture mismatch", expected: expected, actual: actual}}
      end
    end
  end

  def format_report(report),
    do: "final_percentage=#{report.final_percentage} letter_display=#{report.letter_display}"

  defp decode(content) do
    {:ok, :json.decode(content)}
  rescue
    error ->
      {:error, %{reason_code: "gradebook fixture parse failed", detail: Exception.message(error)}}
  end

  defp scheme(rows), do: Enum.map(rows, &{&1["letter"], &1["threshold"]})
end
