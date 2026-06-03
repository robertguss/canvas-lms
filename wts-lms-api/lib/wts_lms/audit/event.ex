defmodule WtsLms.Audit.Event do
  @moduledoc """
  Safe audit event shape for protected WTS coursework actions.
  """

  @enforce_keys [
    :actor_id,
    :action,
    :target_type,
    :target_id,
    :timestamp,
    :outcome,
    :reason_code
  ]
  defstruct [
    :actor_id,
    :action,
    :target_type,
    :target_id,
    :course_id,
    :timestamp,
    :outcome,
    :reason_code,
    metadata: %{}
  ]
end
