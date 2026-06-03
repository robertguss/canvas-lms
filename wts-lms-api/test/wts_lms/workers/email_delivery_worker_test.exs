defmodule WtsLms.Workers.EmailDeliveryWorkerTest do
  use ExUnit.Case, async: true

  alias WtsLms.Workers.EmailDeliveryWorker

  @now ~U[2027-02-03 14:15:00Z]

  test "builds an Oban-compatible email job with Postmark-safe metadata" do
    assert job =
             EmailDeliveryWorker.new(%{
               to: "student@example.edu",
               template: "grade_released",
               subject: "Grade released",
               body: "A grade is available.",
               event_id: "event-grade-released-grade-1"
             })

    assert job.worker == EmailDeliveryWorker
    assert job.queue == :notifications
    assert job.args.message_stream == "outbound"
    assert job.args.to == "student@example.edu"
    assert job.args.event_id == "event-grade-released-grade-1"
    assert job.attempts == 0
    assert job.max_attempts == 5
    refute inspect(job) =~ "token"
    refute Map.has_key?(job.args, :api_token)
  end

  test "successful delivery records audit state without secrets" do
    adapter = fn request ->
      {:ok, %{provider: :postmark, message_id: "postmark-1", to: request.to}}
    end

    job =
      EmailDeliveryWorker.new(%{
        to: "student@example.edu",
        subject: "Hello",
        body: "Body",
        event_id: "event-1"
      })

    assert {:ok, audit} = EmailDeliveryWorker.perform(job, adapter, now: @now)

    assert audit == %{
             event_id: "event-1",
             provider: :postmark,
             provider_message_id: "postmark-1",
             state: :delivered,
             attempts: 1,
             delivered_at: @now
           }
  end

  test "delivery failure records retry audit state" do
    adapter = fn _request -> {:error, :smtp_timeout} end

    job =
      EmailDeliveryWorker.new(%{
        to: "student@example.edu",
        subject: "Hello",
        body: "Body",
        event_id: "event-1"
      })

    assert {:retry, retry} = EmailDeliveryWorker.perform(job, adapter, now: @now)

    assert retry.event_id == "event-1"
    assert retry.state == :retry_scheduled
    assert retry.attempts == 1
    assert retry.max_attempts == 5
    assert retry.error_reason == "smtp_timeout"
    assert retry.next_retry_at == ~U[2027-02-03 14:16:00Z]
  end

  test "final delivery failure records terminal state" do
    adapter = fn _request -> {:error, "provider unavailable"} end

    job =
      EmailDeliveryWorker.new(%{
        to: "student@example.edu",
        subject: "Hello",
        body: "Body",
        event_id: "event-1"
      })
      |> Map.put(:attempts, 4)

    assert {:error, audit} = EmailDeliveryWorker.perform(job, adapter, now: @now)

    assert audit.state == :failed
    assert audit.attempts == 5
    assert audit.max_attempts == 5
    assert audit.error_reason == "provider unavailable"
    assert audit.next_retry_at == nil
  end
end
