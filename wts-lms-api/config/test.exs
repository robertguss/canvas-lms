import Config

config :wts_lms_api,
  env: :test,
  contract_strict?: true

config :logger, level: :warning

config :wts_lms_api, WtsLmsWeb.Endpoint,
  server: false,
  secret_key_base: String.duplicate("a", 64)
