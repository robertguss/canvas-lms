defmodule WtsLmsWeb.ContractHarnessTest do
  use ExUnit.Case, async: true

  alias WtsLmsWeb.ContractHarness

  @course_index_schema %{
    "data" => {:list, %{"id" => :string, "name" => :string}},
    "meta" => %{"request_id" => :string}
  }

  test "accepts valid placeholder API response shape" do
    response = %{
      "data" => [%{"id" => "course-1", "name" => "Foundations"}],
      "meta" => %{"request_id" => "req-1"}
    }

    assert :ok = ContractHarness.validate_json_shape(response, @course_index_schema)
  end

  @tag :rejects_invalid_shape
  test "rejects invalid response shapes" do
    invalid_response = %{
      "data" => [%{"id" => 123, "name" => "Foundations"}],
      "meta" => %{"request_id" => "req-1"}
    }

    assert {:error, ["data[0].id expected string, got integer"]} =
             ContractHarness.validate_json_shape(invalid_response, @course_index_schema)
  end
end
