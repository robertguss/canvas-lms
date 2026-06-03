defmodule WtsLms.Assignments.SubmissionsTest do
  use ExUnit.Case, async: true

  alias WtsLms.Assignments
  alias WtsLms.Schema.{Assignment, Course, Enrollment, Role, Section, User}

  @now ~U[2027-01-12 15:30:00Z]

  test "student submits a text-entry assignment with a timestamp" do
    fixture = fixture(:text_entry)

    assert {:ok, result} =
             Assignments.submit_assignment(
               fixture.assignment.id,
               fixture.student,
               %{body_html: "<p>My reflection.</p>"},
               opts(fixture)
             )

    assert result.submission.assignment_id == fixture.assignment.id
    assert result.submission.user_id == fixture.student.id
    assert result.submission.enrollment_id == fixture.student_enrollment.id
    assert result.submission.state == :submitted
    assert result.submission.body_html == "<p>My reflection.</p>"
    assert result.submission.submitted_at == @now
    assert result.attachments == []
  end

  test "student submits file-upload assignment with sanitized attachment metadata only" do
    fixture = fixture(:file_upload)

    assert {:ok, result} =
             Assignments.submit_assignment(
               fixture.assignment.id,
               fixture.student,
               %{
                 attachments: [
                   %{
                     display_name: "../sermon notes.pdf",
                     content_type: "application/pdf",
                     byte_size: 42_000,
                     checksum: "sha256-notes",
                     storage_key: "tenant/course/submission/private-object"
                   }
                 ]
               },
               opts(fixture)
             )

    assert result.submission.attachment_file_ids == ["file-submission-1"]
    assert result.submission.body_html == nil

    assert [attachment] = result.attachments
    assert attachment.id == "file-submission-1"
    assert attachment.display_name == "sermon notes.pdf"
    assert attachment.content_type == "application/pdf"
    assert attachment.byte_size == 42_000
    assert attachment.checksum == "sha256-notes"
    assert attachment.storage_key == "tenant/course/submission/private-object"
    refute Map.has_key?(Map.from_struct(attachment), :url)
    refute Map.has_key?(Map.from_struct(attachment), :bytes)
  end

  test "no-submission assignment records acknowledgement without body or file payload" do
    fixture = fixture(:none)

    assert {:ok, result} =
             Assignments.submit_assignment(
               fixture.assignment.id,
               fixture.student,
               %{},
               opts(fixture)
             )

    assert result.submission.state == :acknowledged
    assert result.submission.submitted_at == @now
    assert result.submission.body_html == nil
    assert result.submission.attachment_file_ids == []
    assert result.attachments == []
  end

  test "submission comment stores author timestamp body and redaction boundaries" do
    fixture = fixture(:text_entry)

    assert {:ok, result} =
             Assignments.submit_assignment(
               fixture.assignment.id,
               fixture.student,
               %{body_html: "<p>My reflection.</p>"},
               opts(fixture)
             )

    assert {:ok, updated_submission} =
             Assignments.add_comment(
               result.submission.id,
               fixture.teacher,
               %{body: "Please expand the second paragraph."},
               opts(fixture, submissions: [result.submission])
             )

    assert [comment] = updated_submission.comments
    assert comment.author_user_id == fixture.teacher.id
    assert comment.author_display_name == "Teacher One"
    assert comment.body == "Please expand the second paragraph."
    assert comment.created_at == @now

    assert comment.redaction_boundary == %{
             redactable_fields: [:body],
             retained_fields: [:id, :author_user_id, :created_at]
           }
  end

  test "unsupported submission modes stay outside Task 8 scope" do
    fixture = fixture(:online_quiz)

    assert {:error, %{status: 422, reason_code: "unsupported submission type"}} =
             Assignments.submit_assignment(
               fixture.assignment.id,
               fixture.student,
               %{body_html: "<p>Not allowed.</p>"},
               opts(fixture)
             )
  end

  defp fixture(submission_type) do
    student_role =
      Role.new!(%{id: "role-student", name: "Student", kind: :student, account_id: "acct-1"})

    teacher_role =
      Role.new!(%{id: "role-teacher", name: "Teacher", kind: :teacher, account_id: "acct-1"})

    student = user("student-1", "Student One")
    teacher = user("teacher-1", "Teacher One")
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

    student_enrollment =
      enrollment("enrollment-student", course, section, student, student_role, :active)

    teacher_enrollment =
      enrollment("enrollment-teacher", course, section, teacher, teacher_role, :active)

    %{
      student: student,
      teacher: teacher,
      outsider: outsider,
      course: course,
      assignment: assignment,
      roles: [student_role, teacher_role],
      enrollments: [student_enrollment, teacher_enrollment],
      student_enrollment: student_enrollment,
      files: []
    }
  end

  defp opts(fixture, extra \\ []) do
    Keyword.merge(
      [
        courses: [fixture.course],
        assignments: [fixture.assignment],
        roles: fixture.roles,
        enrollments: fixture.enrollments,
        files: fixture.files,
        now: @now,
        max_upload_bytes: 1_000_000
      ],
      extra
    )
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
