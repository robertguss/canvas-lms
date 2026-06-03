defmodule WtsLmsWeb.SubmissionController do
  @moduledoc """
  Thin Phoenix-compatible controller surface for assignment submissions and file downloads.
  """

  alias WtsLms.Assignments
  alias WtsLms.Files

  def create(params, current_user, opts \\ []) do
    assignment_id = value(params, :assignment_id)

    case Assignments.submit_assignment(assignment_id, current_user, params, opts) do
      {:ok, result} -> %{status: 201, data: result}
      {:error, error} -> error_response(error)
    end
  end

  def download_file(params, current_user, opts \\ []) do
    file_id = value(params, :file_id)

    case Files.download_url(file_id, current_user, opts) do
      {:ok, result} -> %{status: 200, data: result}
      {:error, error} -> error_response(error)
    end
  end

  defp error_response(%{status: status, reason_code: reason_code} = error) do
    error_payload = %{reason_code: reason_code}

    error_payload =
      if Map.has_key?(error, :object_url) do
        Map.put(error_payload, :object_url, Map.get(error, :object_url))
      else
        error_payload
      end

    %{status: status, error: error_payload}
  end

  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
