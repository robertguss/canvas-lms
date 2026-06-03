defmodule WtsLms.Notifications.Event do
  @moduledoc false

  defstruct [:id, :type, :course_id, :subject_id, :title, :body, :metadata, :created_at]
end
