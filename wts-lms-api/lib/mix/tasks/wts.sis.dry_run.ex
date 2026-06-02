defmodule Mix.Tasks.Wts.Sis.DryRun do
  @moduledoc "Run a deterministic WTS SIS dry-run import report."
  @shortdoc "Runs WTS SIS dry-run validation"

  use Mix.Task

  alias WtsLms.Sis.DryRun

  @impl true
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: [fixture: :string])

    cond do
      invalid != [] ->
        Mix.raise("Unsupported options: #{inspect(invalid)}")

      is_nil(opts[:fixture]) ->
        Mix.raise("Expected --fixture PATH")

      true ->
        case DryRun.run_file(opts[:fixture]) do
          {:ok, report} -> Mix.shell().info(DryRun.format_report(report))
          {:error, error} -> Mix.raise("SIS dry-run failed: #{inspect(error)}")
        end
    end
  end
end
