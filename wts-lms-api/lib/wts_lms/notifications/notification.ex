defmodule WtsLms.Notifications.Notification do
  @moduledoc false

  defstruct [
    :id,
    :recipient_user_id,
    :course_id,
    :event_type,
    :title,
    :body,
    :metadata,
    :read_at,
    :created_at
  ]
end
