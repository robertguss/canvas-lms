defmodule WtsLmsApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :wts_lms_api,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {WtsLmsApi.Application, []}
    ]
  end

  defp deps do
    []
  end
end
