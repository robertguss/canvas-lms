import Config

config :wts_lms_api,
  ecto_repos: [],
  api_contracts_path: "priv/openapi",
  oban_enabled: false,
  s3_bucket: System.get_env("WTS_LMS_S3_BUCKET"),
  mailer_from: System.get_env("WTS_LMS_MAILER_FROM")

config :wts_lms_api, WtsLmsWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [formats: [json: WtsLmsWeb.ErrorJSON]],
  pubsub_server: WtsLmsApi.PubSub

import_config "#{config_env()}.exs"
