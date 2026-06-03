import Config

config :wts_lms_api,
  env: :test,
  contract_strict?: true

config :logger, level: :warning

config :wts_lms_api, WtsLms.Repo,
  username:
    System.get_env(
      "WTS_LMS_TEST_DB_USER",
      System.get_env("WTS_LMS_DB_USER", System.get_env("USER", "postgres"))
    ),
  password: System.get_env("WTS_LMS_TEST_DB_PASSWORD", System.get_env("WTS_LMS_DB_PASSWORD", "")),
  hostname:
    System.get_env("WTS_LMS_TEST_DB_HOST", System.get_env("WTS_LMS_DB_HOST", "localhost")),
  port:
    String.to_integer(
      System.get_env("WTS_LMS_TEST_DB_PORT", System.get_env("WTS_LMS_DB_PORT", "5432"))
    ),
  database: System.get_env("WTS_LMS_TEST_DB_NAME", "wts_lms_api_test"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: String.to_integer(System.get_env("WTS_LMS_TEST_DB_POOL_SIZE", "10")),
  ownership_timeout: 60_000,
  stacktrace: true,
  show_sensitive_data_on_connection_error: false

config :wts_lms_api, WtsLmsWeb.Endpoint,
  server: false,
  secret_key_base: String.duplicate("a", 64)
