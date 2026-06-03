defmodule WtsLms.Security.SecureLogTest do
  use ExUnit.Case, async: true

  alias WtsLms.Security.SecureLog

  test "sanitizes PII secrets tokens URLs SAML materials and file contents" do
    payload = %{
      access_token: "abc123",
      authorization: "Bearer abc123",
      email: "student@example.edu",
      message_body: "private message",
      file_content: "file bytes",
      raw_url: "https://storage.example/private/file.pdf?token=abc123",
      saml_assertion: "assertion",
      certificate: "-----BEGIN CERTIFICATE----- cert",
      private_key: "-----BEGIN PRIVATE KEY----- key",
      safe_count: 4,
      nested: %{body_html: "submission body", reason_code: "valid assertion"}
    }

    sanitized = SecureLog.sanitize(payload)
    inspected = inspect(sanitized)

    assert sanitized.safe_count == 4
    assert sanitized.nested.reason_code == "valid assertion"
    assert sanitized.access_token == "[REDACTED]"
    assert sanitized.authorization == "[REDACTED]"
    assert sanitized.email == "[REDACTED]"
    assert sanitized.raw_url == "[REDACTED]"
    assert sanitized.nested.body_html == "[REDACTED]"
    refute inspected =~ "abc123"
    refute inspected =~ "student@example.edu"
    refute inspected =~ "private message"
    refute inspected =~ "file bytes"
    refute inspected =~ "storage.example"
    refute inspected =~ "BEGIN PRIVATE KEY"
  end

  test "redacts bearer tokens embedded in strings" do
    sanitized = SecureLog.sanitize(%{detail: "Authorization: Bearer secret-token sent"})

    assert sanitized.detail == "Authorization: [REDACTED] sent"
    refute inspect(sanitized) =~ "secret-token"
  end
end
