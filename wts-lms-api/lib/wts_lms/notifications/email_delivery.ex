defmodule WtsLms.Notifications.EmailDelivery do
  @moduledoc """
  Placeholder-safe Postmark delivery request shaping for notification email.
  """

  @default_message_stream "outbound"

  def request(recipient, event, opts \\ []) do
    %{
      to: value(recipient, :email),
      template: template_for(event.type),
      subject: event.title,
      body: event.body,
      message_stream: Keyword.get(opts, :message_stream, @default_message_stream),
      event_id: event.id,
      metadata: %{
        event_id: event.id,
        event_type: event.type,
        recipient_user_id: value(recipient, :id)
      }
    }
  end

  defp template_for(:announcement_published), do: "announcement_published"
  defp template_for(:announcement_updated), do: "announcement_updated"
  defp template_for(:due_date_changed), do: "due_date_changed"
  defp template_for(:submission_comment_added), do: "submission_comment_added"
  defp template_for(:grade_released), do: "grade_released"

  defp value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
end
