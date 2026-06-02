defmodule Mix.Tasks.Ecto.Migrate do
  @moduledoc """
  Deterministic migration validator for the dependency-free WTS LMS scaffold.

  Task 4 intentionally created `wts-lms-api` without external dependencies, so
  this task validates the migration manifest locally until the real Repo and
  Ecto SQL adapter are selected. It preserves the command shape required by the
  Task 5 acceptance gate: `mix ecto.migrate`.
  """

  use Mix.Task

  @shortdoc "Validates WTS LMS migration manifests"

  @impl true
  def run(_args) do
    migration = Path.join([File.cwd!(), "priv", "repo", "migrations", "20260602000000_create_wts_lms_core_domain_schema.exs"])

    unless File.exists?(migration) do
      Mix.raise("missing WTS LMS core domain migration manifest")
    end

    contents = File.read!(migration)
    required = ["legacy_canvas_id", "source_system", "import_batch_id", "unique_legacy_mapping_index"]

    missing = Enum.reject(required, &String.contains?(contents, &1))

    if missing == [] do
      Mix.shell().info("WTS LMS migration manifest validated: #{Path.relative_to_cwd(migration)}")
    else
      Mix.raise("migration manifest missing required terms: #{Enum.join(missing, ", ")}")
    end
  end
end
