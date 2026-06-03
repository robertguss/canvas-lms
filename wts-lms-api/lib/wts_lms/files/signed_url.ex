defmodule WtsLms.Files.SignedUrl do
  @moduledoc """
  Deterministic S3-compatible signed URL boundary metadata.
  """

  @default_endpoint "https://storage.example.invalid"
  @default_bucket "wts-lms"
  @default_ttl_seconds 900

  def mint(method, storage_key, opts \\ []) do
    now = Keyword.get(opts, :now) || DateTime.utc_now() |> DateTime.truncate(:second)
    ttl_seconds = Keyword.get(opts, :ttl_seconds, @default_ttl_seconds)
    expires_at = DateTime.add(now, ttl_seconds, :second)
    headers = Keyword.get(opts, :headers, %{})
    storage = Keyword.get(opts, :storage, %{})
    endpoint = storage |> Map.get(:endpoint, @default_endpoint) |> String.trim_trailing("/")
    bucket = Map.get(storage, :bucket, @default_bucket)
    object_ref = object_ref(storage_key)

    %{
      method: method,
      url:
        endpoint <>
          "/" <> bucket <> "/" <> object_ref <> "?expires=" <> DateTime.to_iso8601(expires_at),
      object_ref: object_ref,
      expires_at: expires_at,
      headers: headers,
      signature: signature(method, storage_key, expires_at, headers)
    }
  end

  def object_ref(storage_key) do
    digest = :crypto.hash(:sha256, to_string(storage_key)) |> Base.url_encode64(padding: false)
    "obj_" <> String.slice(digest, 0, 32)
  end

  defp signature(method, storage_key, expires_at, headers) do
    material =
      [
        Atom.to_string(method),
        to_string(storage_key),
        DateTime.to_iso8601(expires_at),
        headers |> Enum.sort() |> inspect()
      ]
      |> Enum.join("|")

    :crypto.hash(:sha256, material) |> Base.url_encode64(padding: false)
  end
end
