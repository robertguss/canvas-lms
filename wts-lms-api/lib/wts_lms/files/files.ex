defmodule WtsLms.Files do
  @moduledoc """
  File metadata and authorized S3-compatible URL minting for WTS coursework.
  """

  alias WtsLms.Authorization.RoleAuthorization
  alias WtsLms.Files.SignedUrl
  alias WtsLms.Schema.ContentFile

  @active_states [:active, "active"]
  @default_max_upload_bytes 25 * 1024 * 1024

  def request_upload_url(course_id, user, metadata, opts \\ []) do
    with :ok <- authorize_course_user(course_id, user, opts),
         {:ok, sanitized} <- sanitize_upload_metadata(metadata, opts) do
      storage_key = storage_key(course_id, user, sanitized.display_name)

      file =
        ContentFile.new!(%{
          id: Map.get(sanitized, :id, "file-upload-" <> SignedUrl.object_ref(storage_key)),
          course_id: course_id,
          uploaded_by_user_id: value(user, :id),
          display_name: sanitized.display_name,
          storage_key: storage_key,
          content_type: sanitized.content_type,
          byte_size: sanitized.byte_size,
          checksum: sanitized.checksum,
          visibility: :course
        })

      headers = signed_headers(file)
      upload = SignedUrl.mint(:put, storage_key, signed_url_opts(opts, headers))

      {:ok, %{file: file, upload: upload}}
    end
  end

  def download_url(file_id, user, opts \\ []) do
    with {:ok, file} <- find_file(file_id, Keyword.get(opts, :files, [])),
         :ok <- storage_object_present(file),
         :ok <- authorize_course_user(value(file, :course_id), user, opts) do
      download = SignedUrl.mint(:get, value(file, :storage_key), signed_url_opts(opts, %{}))
      {:ok, %{file: file_metadata(file), download: download}}
    else
      {:error, %{status: 403} = error} -> {:error, Map.put_new(error, :object_url, nil)}
      {:error, error} -> {:error, error}
    end
  end

  def sanitize_attachment_metadata(assignment, user, attachment, index, opts \\ []) do
    with {:ok, sanitized} <- sanitize_upload_metadata(attachment, opts) do
      storage_key =
        Map.get(attachment, :storage_key) || Map.get(attachment, "storage_key") ||
          storage_key(value(assignment, :course_id), user, sanitized.display_name)

      {:ok,
       ContentFile.new!(%{
         id:
           Map.get(attachment, :id) || Map.get(attachment, "id") || "file-submission-#{index + 1}",
         course_id: value(assignment, :course_id),
         submission_id:
           Map.get(attachment, :submission_id) || Map.get(attachment, "submission_id"),
         uploaded_by_user_id: value(user, :id),
         display_name: sanitized.display_name,
         storage_key: storage_key,
         content_type: sanitized.content_type,
         byte_size: sanitized.byte_size,
         checksum: sanitized.checksum,
         visibility: :submission
       })}
    end
  end

  defp find_file(file_id, files) do
    case Enum.find(files, &(value(&1, :id) == file_id)) do
      nil ->
        {:error,
         %{
           status: 404,
           reason_code: "file missing",
           action: "ask the instructor to re-upload the file or contact support",
           object_url: nil
         }}

      file ->
        {:ok, file}
    end
  end

  defp storage_object_present(file) do
    if blank?(value(file, :storage_key)) do
      {:error,
       %{
         status: 404,
         reason_code: "file missing",
         action: "ask the instructor to re-upload the file or contact support",
         object_url: nil
       }}
    else
      :ok
    end
  end

  defp authorize_course_user(course_id, user, opts) do
    enrollments = Keyword.get(opts, :enrollments, [])
    roles = Keyword.get(opts, :roles, [])
    course_enrollments = Enum.filter(enrollments, &(value(&1, :course_id) == course_id))

    active_enrolled? =
      Enum.any?(course_enrollments, fn enrollment ->
        value(enrollment, :user_id) == value(user, :id) &&
          value(enrollment, :state) in @active_states
      end)

    if active_enrolled? do
      case RoleAuthorization.authorize(user, roles: roles, enrollments: course_enrollments) do
        {:ok, _authorization} -> :ok
        {:error, _error} -> {:error, forbidden()}
      end
    else
      {:error, forbidden()}
    end
  end

  defp forbidden, do: %{status: 403, reason_code: "file download forbidden", object_url: nil}

  defp sanitize_upload_metadata(metadata, opts) do
    byte_size = int_value(metadata, :byte_size)
    max_upload_bytes = Keyword.get(opts, :max_upload_bytes, @default_max_upload_bytes)

    cond do
      blank?(value(metadata, :display_name)) ->
        {:error, %{status: 422, reason_code: "missing file name", object_url: nil}}

      blank?(value(metadata, :content_type)) ->
        {:error, %{status: 422, reason_code: "missing content type", object_url: nil}}

      blank?(value(metadata, :checksum)) ->
        {:error, %{status: 422, reason_code: "missing checksum", object_url: nil}}

      byte_size == nil || byte_size < 0 ->
        {:error, %{status: 422, reason_code: "invalid byte size", object_url: nil}}

      byte_size > max_upload_bytes ->
        {:error,
         %{
           status: 413,
           reason_code: "file too large",
           max_upload_bytes: max_upload_bytes,
           object_url: nil
         }}

      true ->
        {:ok,
         %{
           display_name: sanitize_display_name(value(metadata, :display_name)),
           content_type: value(metadata, :content_type),
           byte_size: byte_size,
           checksum: value(metadata, :checksum)
         }}
    end
  end

  defp signed_headers(file) do
    %{
      "Content-Type" => value(file, :content_type),
      "x-amz-checksum-sha256" => value(file, :checksum)
    }
  end

  defp signed_url_opts(opts, headers) do
    [
      now: Keyword.get(opts, :now),
      ttl_seconds: Keyword.get(opts, :ttl_seconds, 900),
      headers: headers,
      storage: Keyword.get(opts, :storage, %{})
    ]
  end

  defp file_metadata(file) do
    %{
      id: value(file, :id),
      display_name: value(file, :display_name),
      content_type: value(file, :content_type),
      byte_size: value(file, :byte_size),
      checksum: value(file, :checksum)
    }
  end

  defp storage_key(course_id, user, display_name) do
    course_id <> "/" <> value(user, :id) <> "/" <> display_name
  end

  defp sanitize_display_name(display_name) do
    display_name
    |> to_string()
    |> Path.basename()
    |> String.replace(~r/[^A-Za-z0-9._ -]/, "_")
    |> String.trim()
  end

  defp int_value(map, key) do
    case value(map, key) do
      value when is_integer(value) -> value
      value when is_binary(value) -> String.to_integer(value)
      _other -> nil
    end
  rescue
    ArgumentError -> nil
  end

  defp blank?(value), do: value in [nil, ""] || (is_binary(value) && String.trim(value) == "")
  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
