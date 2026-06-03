defmodule WtsLmsWeb.SubmissionControllerTest do
  use ExUnit.Case, async: true

  alias WtsLms.Schema.{Assignment, ContentFile, Course, Enrollment, Role, Section, User}
  alias WtsLmsWeb.SubmissionController

  @now ~U[2027-01-12 15:30:00Z]

  test "create returns a submitted text-entry response for an enrolled student" do
    fixture = fixture(:text_entry)

    assert %{status: 201, data: data} =
             SubmissionController.create(
               %{"assignment_id" => fixture.assignment.id, "body_html" => "<p>Ready.</p>"},
               fixture.student,
               opts(fixture)
             )

    assert data.submission.assignment_id == fixture.assignment.id
    assert data.submission.state == :submitted
    assert data.submission.submitted_at == @now
    assert data.attachments == []
  end

  test "download returns 403 without object URL for non-enrolled users" do
    fixture = fixture(:file_upload)

    response =
      SubmissionController.download_file(
        %{"file_id" => fixture.file.id},
        fixture.outsider,
        opts(fixture)
      )

    assert response == %{
             status: 403,
             error: %{reason_code: "file download forbidden", object_url: nil}
           }
  end

  defp fixture(submission_type) do
    student_role =
      Role.new!(%{id: "role-student", name: "Student", kind: :student, account_id: "acct-1"})

    student = user("student-1", "Student One")
    outsider = user("outsider-1", "Outsider One")

    course =
      Course.new!(%{
        id: "course-1",
        account_id: "acct-1",
        term_id: "term-1",
        sis_course_id: "sis-course-1",
        name: "Foundations of Theology",
        code: "THEO-101"
      })

    section =
      Section.new!(%{
        id: "section-1",
        course_id: course.id,
        sis_section_id: "sis-section-1",
        name: "A"
      })

    enrollment = enrollment("enrollment-student", course, section, student, student_role, :active)

    assignment =
      Assignment.new!(%{
        id: "assignment-1",
        course_id: course.id,
        assignment_group_id: "group-1",
        title: "Reflection 1",
        description_html: "<p>Submit work.</p>",
        submission_types: [submission_type],
        points_possible: "10.0"
      })

    file =
      ContentFile.new!(%{
        id: "file-1",
        course_id: course.id,
        uploaded_by_user_id: student.id,
        display_name: "notes.pdf",
        storage_key: "course-1/private/notes.pdf",
        content_type: "application/pdf",
        byte_size: 500_000,
        checksum: "sha256-notes"
      })

    %{
      student: student,
      outsider: outsider,
      course: course,
      assignment: assignment,
      roles: [student_role],
      enrollments: [enrollment],
      file: file
    }
  end

  defp opts(fixture) do
    [
      courses: [fixture.course],
      assignments: [fixture.assignment],
      roles: fixture.roles,
      enrollments: fixture.enrollments,
      files: [fixture.file],
      now: @now,
      max_upload_bytes: 1_000_000,
      storage: %{endpoint: "https://storage.example.invalid", bucket: "wts-lms-test"}
    ]
  end

  defp user(id, display_name) do
    User.new!(%{
      id: id,
      sis_user_id: "sis-#{id}",
      display_name: display_name,
      email: "#{id}@example.edu",
      role_ids: [],
      status: :active
    })
  end

  defp enrollment(id, course, section, user, role, state) do
    Enrollment.new!(%{
      id: id,
      course_id: course.id,
      section_id: section.id,
      user_id: user.id,
      role_id: role.id,
      state: state,
      owner_system: :sis
    })
  end
end
