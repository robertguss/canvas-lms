import Config

config :wts_lms_api,
  env: :dev,
  contract_strict?: false

config :logger, level: :info

config :wts_lms_api, WtsLms.Repo,
  username: System.get_env("WTS_LMS_DB_USER", System.get_env("USER", "postgres")),
  password: System.get_env("WTS_LMS_DB_PASSWORD", ""),
  hostname: System.get_env("WTS_LMS_DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("WTS_LMS_DB_PORT", "5432")),
  database: System.get_env("WTS_LMS_DB_NAME", "wts_lms_api_dev"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: false,
  pool_size: String.to_integer(System.get_env("WTS_LMS_DB_POOL_SIZE", "10"))

config :wts_lms_api, WtsLmsWeb.Endpoint,
  server: false,
  secret_key_base: String.duplicate("d", 64)
