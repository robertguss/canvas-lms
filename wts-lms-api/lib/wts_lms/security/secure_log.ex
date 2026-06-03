defmodule WtsLms.Security.SecureLog do
  @moduledoc """
  Deterministic log sanitization for FERPA-sensitive coursework data.
  """

  @redacted "[REDACTED]"
  @sensitive_keys MapSet.new([
                    "access_token",
                    "authorization",
                    "bearer_token",
                    "body",
                    "body_html",
                    "certificate",
                    "email",
                    "file_content",
                    "message_body",
                    "object_url",
                    "private_key",
                    "raw_url",
                    "saml_assertion",
                    "storage_key",
                    "submission_body"
                  ])

  def redacted, do: @redacted

  def sensitive_key?(key), do: MapSet.member?(@sensitive_keys, key_name(key))

  def sanitize(value) when is_map(value) and not is_struct(value) do
    Map.new(value, fn {key, item} ->
      if sensitive_key?(key) do
        {key, @redacted}
      else
        {key, sanitize(item)}
      end
    end)
  end

  def sanitize(value) when is_list(value), do: Enum.map(value, &sanitize/1)
  def sanitize(value) when is_binary(value), do: redact_string(value)
  def sanitize(value), do: value

  defp redact_string(value) do
    value
    |> String.replace(~r/Bearer\s+[^\s,;]+/i, @redacted)
    |> redact_url()
    |> redact_secret_material()
  end

  defp redact_url(value) do
    String.replace(value, ~r/(https?:\/\/|s3:\/\/)[^\s]+/i, @redacted)
  end

  defp redact_secret_material(value) do
    if String.contains?(value, ["BEGIN PRIVATE KEY", "BEGIN CERTIFICATE"]) do
      @redacted
    else
      value
    end
  end

  defp key_name(key) when is_atom(key), do: Atom.to_string(key)
  defp key_name(key), do: key |> to_string() |> String.downcase()
end
