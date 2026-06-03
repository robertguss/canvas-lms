defmodule WtsLms.Workers.EmailDeliveryWorker do
  @moduledoc """
  Oban-compatible notification email job boundary without requiring Oban at compile time.
  """

  @default_queue :notifications
  @default_max_attempts 5
  @default_message_stream "outbound"

  def new(args) when is_map(args) do
    %{
      worker: __MODULE__,
      queue: @default_queue,
      args: normalize_args(args),
      attempts: 0,
      max_attempts: @default_max_attempts
    }
  end

  def perform(job, adapter, opts \\ []) when is_function(adapter, 1) do
    now = Keyword.get(opts, :now) || DateTime.utc_now() |> DateTime.truncate(:second)
    attempts = Map.get(job, :attempts, 0) + 1
    max_attempts = Map.get(job, :max_attempts, @default_max_attempts)

    case adapter.(job.args) do
      {:ok, response} ->
        {:ok,
         %{
           event_id: job.args.event_id,
           provider: value(response, :provider) || :postmark,
           provider_message_id: value(response, :message_id),
           state: :delivered,
           attempts: attempts,
           delivered_at: now
         }}

      {:error, reason} ->
        failure_result(job.args.event_id, reason, attempts, max_attempts, now)
    end
  end

  defp failure_result(event_id, reason, attempts, max_attempts, now) do
    audit = %{
      event_id: event_id,
      state: if(attempts >= max_attempts, do: :failed, else: :retry_scheduled),
      attempts: attempts,
      max_attempts: max_attempts,
      error_reason: to_string(reason),
      next_retry_at: next_retry_at(attempts, max_attempts, now)
    }

    if audit.state == :failed, do: {:error, audit}, else: {:retry, audit}
  end

  defp next_retry_at(attempts, max_attempts, _now) when attempts >= max_attempts, do: nil
  defp next_retry_at(attempts, _max_attempts, now), do: DateTime.add(now, attempts * 60, :second)

  defp normalize_args(args) do
    %{
      to: value(args, :to),
      template: value(args, :template),
      subject: value(args, :subject),
      body: value(args, :body),
      message_stream: value(args, :message_stream) || @default_message_stream,
      event_id: value(args, :event_id),
      metadata: value(args, :metadata) || %{}
    }
  end

  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
