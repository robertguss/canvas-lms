import Config

config :wts_lms_api,
  env: :dev,
  contract_strict?: false

config :logger, level: :info

config :wts_lms_api, WtsLmsWeb.Endpoint,
  server: false,
  secret_key_base: String.duplicate("d", 64)
