defmodule WtsLms.CourseContentTest do
  use ExUnit.Case, async: true

  @compile {:no_warn_undefined, WtsLms.CourseContentFixture}

  alias WtsLms.CourseContent
  alias WtsLms.CourseContentFixture

  test "enrolled student receives stable course home syllabus and coursework content" do
    fixture = CourseContentFixture.fixture()

    assert {:ok, content} =
             CourseContent.get_course_content(
               fixture.course.id,
               fixture.student,
               CourseContentFixture.opts(fixture)
             )

    assert content.course == %{
             id: "course-1",
             name: "Foundations of Theology",
             code: "THEO-101",
             syllabus_html: "<p>Read, discuss, and submit weekly reflections.</p>"
           }

    assert [%{id: "module-1", title: "Week 1", position: 1, pages: [page], files: [file]}] =
             content.modules

    assert page == %{
             id: "page-1",
             title: "Welcome Reading",
             slug: "welcome-reading",
             body_html: "<p>Begin here.</p>"
           }

    assert file == %{
             id: "file-1",
             display_name: "week-1-reading.pdf",
             content_type: "application/pdf",
             byte_size: 1234,
             checksum: "sha256-week-1"
           }

    assert content.pages == [page]
    assert content.files == [file]

    assert content.announcements == [
             %{
               id: "announcement-1",
               title: "Welcome to week one",
               message_html: "<p>Please review the syllabus.</p>",
               posted_at: "2027-01-10T16:00:00Z"
             }
           ]

    assert content.calendar_dates == [
             %{
               assignment_id: "assignment-1",
               title: "Reflection 1",
               due_at: "2027-01-17T23:59:00Z",
               available_at: "2027-01-10T00:00:00Z",
               lock_at: "2027-01-18T23:59:00Z"
             }
           ]
  end

  test "enrolled teachers and admins can access the same course content contract" do
    fixture = CourseContentFixture.fixture()

    for user <- [fixture.teacher, fixture.admin] do
      assert {:ok, content} =
               CourseContent.get_course_content(
                 fixture.course.id,
                 user,
                 CourseContentFixture.opts(fixture)
               )

      assert content.course.id == fixture.course.id
      assert [%{title: "Week 1"}] = content.modules
    end
  end

  test "non-enrolled and dropped users receive a 403-style result with no content" do
    fixture = CourseContentFixture.fixture()

    for user <- [fixture.outsider, fixture.dropped_student] do
      assert {:error, error} =
               CourseContent.get_course_content(
                 fixture.course.id,
                 user,
                 CourseContentFixture.opts(fixture)
               )

      assert error.status == 403
      assert error.content == nil
    end
  end
end
