defmodule WtsLmsApi.ApplicationTest do
  use ExUnit.Case, async: true

  test "application starts under Mix test" do
    assert Application.spec(:wts_lms_api, :mod) == {WtsLmsApi.Application, []}
  end
end
