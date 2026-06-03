defmodule Mix.Tasks.Wts.Import.Diff do
  @moduledoc "Run deterministic WTS Canvas import diff verification."
  @shortdoc "Verifies WTS Canvas import fixture fidelity"

  use Mix.Task

  alias WtsLms.Imports

  @impl true
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: [fixture: :string])

    cond do
      invalid != [] ->
        Mix.raise("Unsupported options: #{inspect(invalid)}")

      is_nil(opts[:fixture]) ->
        Mix.raise("Expected --fixture PATH")

      true ->
        case Imports.diff_fixture(opts[:fixture]) do
          {:ok, report} ->
            Mix.shell().info(Imports.format_diff_report(report))

          {:error, report} ->
            Mix.raise("Import diff failed:\n#{Imports.format_diff_report(report)}")
        end
    end
  end
end
