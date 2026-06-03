defmodule WtsLms.NotificationsTest do
  use ExUnit.Case, async: true

  alias WtsLms.Notifications

  alias WtsLms.Schema.{
    Assignment,
    Course,
    Enrollment,
    Grade,
    GradeItem,
    Role,
    Section,
    Submission,
    User
  }

  @now ~U[2027-02-03 14:15:00Z]

  test "grade release sends email job and in-app unread notification" do
    fixture = fixture()

    assert {:ok, result} =
             Notifications.grade_released(
               fixture.grade,
               opts(fixture, grade_items: [fixture.grade_item], assignments: [fixture.assignment])
             )

    assert result.event.type == :grade_released
    assert result.event.id == "event-grade-released-grade-1"

    assert [notification] = result.notifications
    assert notification.id == "notification-event-grade-released-grade-1-student-1"
    assert notification.recipient_user_id == fixture.student.id
    assert notification.course_id == fixture.course.id
    assert notification.event_type == :grade_released
    assert notification.title == "Grade released: Reflection 1"
    assert notification.body == "A grade for Reflection 1 is available."

    assert notification.metadata == %{
             assignment_id: fixture.assignment.id,
             grade_id: fixture.grade.id
           }

    assert notification.read_at == nil
    assert notification.created_at == @now

    assert [job] = result.email_jobs
    assert job.worker == WtsLms.Workers.EmailDeliveryWorker
    assert job.queue == :notifications
    assert job.max_attempts == 5
    assert job.args.to == "student@example.edu"
    assert job.args.template == "grade_released"
    assert job.args.message_stream == "outbound"
    assert job.args.event_id == result.event.id
    refute inspect(job.args) =~ "token"
  end

  test "submission comment notification includes safe metadata and no private object URL" do
    fixture = fixture()

    comment = %{
      id: "comment-1",
      author_user_id: fixture.teacher.id,
      body: "Please expand this.",
      created_at: @now,
      file_url: "https://s3.example.test/private/object",
      object_url: "s3://bucket/private/object"
    }

    assert {:ok, result} =
             Notifications.submission_comment_added(
               fixture.submission,
               comment,
               opts(fixture, assignments: [fixture.assignment])
             )

    assert [notification] = result.notifications
    assert notification.recipient_user_id == fixture.student.id
    assert notification.event_type == :submission_comment_added

    assert notification.metadata == %{
             assignment_id: fixture.assignment.id,
             comment_id: "comment-1",
             submission_id: fixture.submission.id
           }

    refute inspect(notification.metadata) =~ "private/object"
    refute inspect(result.email_jobs) =~ "private/object"
  end

  test "announcement event notifies active enrolled users only" do
    fixture = fixture()

    announcement = %{
      id: "announcement-1",
      course_id: fixture.course.id,
      title: "Chapel schedule",
      message_html: "<p>Updated chapel schedule.</p>",
      status: :published
    }

    assert {:ok, result} = Notifications.announcement_published(announcement, opts(fixture))

    assert result.event.type == :announcement_published

    recipient_ids = Enum.map(result.notifications, & &1.recipient_user_id)
    assert recipient_ids == [fixture.student.id, fixture.teacher.id]
    refute fixture.dropped_student.id in recipient_ids
    refute fixture.outsider.id in recipient_ids

    assert Enum.all?(result.notifications, &(&1.read_at == nil))

    assert Enum.map(result.email_jobs, & &1.args.to) == [
             "student@example.edu",
             "teacher@example.edu"
           ]
  end

  test "updated announcement event is represented separately" do
    fixture = fixture()

    announcement = %{id: "announcement-1", course_id: fixture.course.id, title: "Updated chapel"}

    assert {:ok, result} = Notifications.announcement_updated(announcement, opts(fixture))

    assert result.event.type == :announcement_updated
    assert [%{event_type: :announcement_updated} | _rest] = result.notifications
  end

  test "due-date change event is deterministic" do
    fixture = fixture()

    assert {:ok, first} =
             Notifications.due_date_changed(
               fixture.assignment,
               "2027-02-10T23:59:00Z",
               "2027-02-17T23:59:00Z",
               opts(fixture)
             )

    assert {:ok, second} =
             Notifications.due_date_changed(
               fixture.assignment,
               "2027-02-10T23:59:00Z",
               "2027-02-17T23:59:00Z",
               opts(fixture)
             )

    assert first == second

    assert first.event.id ==
             "event-due-date-changed-assignment-1-2027-02-10T23-59-00Z-2027-02-17T23-59-00Z"

    assert first.event.metadata == %{
             assignment_id: fixture.assignment.id,
             old_due_at: "2027-02-10T23:59:00Z",
             new_due_at: "2027-02-17T23:59:00Z"
           }
  end

  test "notification preferences digests SMS and mobile push stay out of scope" do
    refute function_exported?(Notifications, :set_preferences, 3)
    refute function_exported?(Notifications, :schedule_digest, 2)
    refute :sms in Notifications.supported_channels()
    refute :mobile_push in Notifications.supported_channels()
    refute :digest in Notifications.supported_channels()
  end

  defp fixture do
    student_role =
      Role.new!(%{id: "role-student", account_id: "acct-1", name: "Student", kind: :student})

    teacher_role =
      Role.new!(%{id: "role-teacher", account_id: "acct-1", name: "Teacher", kind: :teacher})

    student = user("student-1", "Student One", "student@example.edu")
    teacher = user("teacher-1", "Teacher One", "teacher@example.edu")
    dropped_student = user("dropped-1", "Dropped One", "dropped@example.edu")
    outsider = user("outsider-1", "Outsider One", "outsider@example.edu")

    course =
      Course.new!(%{
        id: "course-1",
        account_id: "acct-1",
        term_id: "term-1",
        sis_course_id: "THEO-101",
        name: "Foundations",
        code: "THEO-101"
      })

    section =
      Section.new!(%{
        id: "section-1",
        course_id: course.id,
        sis_section_id: "THEO-101-A",
        name: "A"
      })

    assignment =
      Assignment.new!(%{
        id: "assignment-1",
        course_id: course.id,
        assignment_group_id: "group-1",
        title: "Reflection 1",
        due_at: "2027-02-10T23:59:00Z",
        points_possible: "10.0"
      })

    grade_item =
      GradeItem.new!(%{
        id: "grade-item-1",
        course_id: course.id,
        assignment_id: assignment.id,
        assignment_group_id: "group-1",
        title: assignment.title,
        points_possible: assignment.points_possible
      })

    submission =
      Submission.new!(%{
        id: "submission-1",
        assignment_id: assignment.id,
        user_id: student.id,
        enrollment_id: "enrollment-student",
        attempt: 1,
        state: :submitted
      })

    grade =
      Grade.new!(%{
        id: "grade-1",
        grade_item_id: grade_item.id,
        submission_id: submission.id,
        student_user_id: student.id,
        grader_user_id: teacher.id,
        points: "9.0",
        state: :posted,
        posted_at: @now
      })

    %{
      course: course,
      section: section,
      assignment: assignment,
      grade_item: grade_item,
      submission: submission,
      grade: grade,
      roles: [student_role, teacher_role],
      users: [student, teacher, dropped_student, outsider],
      student: student,
      teacher: teacher,
      dropped_student: dropped_student,
      outsider: outsider,
      enrollments: [
        enrollment("enrollment-student", course, section, student, student_role, :active),
        enrollment("enrollment-teacher", course, section, teacher, teacher_role, :active),
        enrollment("enrollment-dropped", course, section, dropped_student, student_role, :dropped)
      ]
    }
  end

  defp opts(fixture, extra \\ []) do
    Keyword.merge(
      [
        users: fixture.users,
        enrollments: fixture.enrollments,
        now: @now
      ],
      extra
    )
  end

  defp user(id, display_name, email) do
    User.new!(%{id: id, sis_user_id: "sis-#{id}", display_name: display_name, email: email})
  end

  defp enrollment(id, course, section, user, role, state) do
    Enrollment.new!(%{
      id: id,
      course_id: course.id,
      section_id: section.id,
      user_id: user.id,
      role_id: role.id,
      state: state
    })
  end
end
