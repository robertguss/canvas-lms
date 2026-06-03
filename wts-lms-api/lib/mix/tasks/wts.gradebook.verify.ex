defmodule Mix.Tasks.Wts.Gradebook.Verify do
  @moduledoc "Run deterministic WTS gradebook fixture verification."
  @shortdoc "Verifies WTS gradebook fixture output"

  use Mix.Task

  alias WtsLms.Gradebook.Verify

  @impl true
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: [fixture: :string])

    cond do
      invalid != [] ->
        Mix.raise("Unsupported options: #{inspect(invalid)}")

      is_nil(opts[:fixture]) ->
        Mix.raise("Expected --fixture PATH")

      true ->
        case Verify.run_file(opts[:fixture]) do
          {:ok, report} -> Mix.shell().info(Verify.format_report(report))
          {:error, error} -> Mix.raise("Gradebook verification failed: #{inspect(error)}")
        end
    end
  end
end
