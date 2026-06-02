defmodule WtsLmsWeb.CourseContentControllerTest do
  use ExUnit.Case, async: true

  @compile {:no_warn_undefined, WtsLms.CourseContentFixture}

  alias WtsLms.CourseContentFixture
  alias WtsLmsWeb.CourseContentController

  test "show returns course content for an enrolled student" do
    fixture = CourseContentFixture.fixture()

    assert %{status: 200, data: data} =
             CourseContentController.show(
               %{"course_id" => fixture.course.id},
               fixture.student,
               CourseContentFixture.opts(fixture)
             )

    assert data.course.name == "Foundations of Theology"
    assert [%{title: "Welcome to week one"}] = data.announcements
    assert [%{title: "Reflection 1"}] = data.calendar_dates
  end

  test "show returns 403 without content payload for non-enrolled users" do
    fixture = CourseContentFixture.fixture()

    response =
      CourseContentController.show(
        %{"course_id" => fixture.course.id},
        fixture.outsider,
        CourseContentFixture.opts(fixture)
      )

    assert response == %{status: 403, error: %{reason_code: "course content forbidden"}}
    refute Map.has_key?(response, :data)
  end
end
