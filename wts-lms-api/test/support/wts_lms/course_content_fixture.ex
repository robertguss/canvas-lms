defmodule WtsLms.CourseContentFixture do
  @moduledoc false

  alias WtsLms.Schema.{
    Assignment,
    ContentFile,
    Course,
    Enrollment,
    LearningModule,
    Page,
    Role,
    Section,
    User
  }

  def fixture do
    student_role =
      Role.new!(%{id: "role-student", name: "Student", kind: :student, account_id: "acct-1"})

    teacher_role =
      Role.new!(%{id: "role-teacher", name: "Teacher", kind: :teacher, account_id: "acct-1"})

    admin_role = Role.new!(%{id: "role-admin", name: "Admin", kind: :admin, account_id: "acct-1"})

    student = user("student-1", "sis-student-1", "Student One")
    teacher = user("teacher-1", "sis-teacher-1", "Teacher One")
    admin = user("admin-1", "sis-admin-1", "Admin One")
    outsider = user("outsider-1", "sis-outsider-1", "Outsider One")
    dropped_student = user("dropped-1", "sis-dropped-1", "Dropped One")

    course =
      Course.new!(%{
        id: "course-1",
        account_id: "acct-1",
        term_id: "term-1",
        sis_course_id: "sis-course-1",
        name: "Foundations of Theology",
        code: "THEO-101",
        syllabus_html: "<p>Read, discuss, and submit weekly reflections.</p>",
        status: :active
      })

    section =
      Section.new!(%{
        id: "section-1",
        course_id: course.id,
        sis_section_id: "sis-section-1",
        name: "A"
      })

    module =
      LearningModule.new!(%{id: "module-1", course_id: course.id, title: "Week 1", position: 1})

    page =
      Page.new!(%{
        id: "page-1",
        course_id: course.id,
        module_id: module.id,
        title: "Welcome Reading",
        slug: "welcome-reading",
        body_html: "<p>Begin here.</p>"
      })

    file =
      ContentFile.new!(%{
        id: "file-1",
        course_id: course.id,
        uploaded_by_user_id: teacher.id,
        display_name: "week-1-reading.pdf",
        storage_key: "course-1/week-1-reading.pdf",
        content_type: "application/pdf",
        byte_size: 1234,
        checksum: "sha256-week-1"
      })

    assignment =
      Assignment.new!(%{
        id: "assignment-1",
        course_id: course.id,
        assignment_group_id: "group-1",
        title: "Reflection 1",
        description_html: "<p>Write one page.</p>",
        submission_types: [:text_entry],
        points_possible: "10.0",
        due_at: "2027-01-17T23:59:00Z",
        available_at: "2027-01-10T00:00:00Z",
        lock_at: "2027-01-18T23:59:00Z"
      })

    roles = [student_role, teacher_role, admin_role]

    enrollments = [
      enrollment("enrollment-student", course, section, student, student_role, :active),
      enrollment("enrollment-teacher", course, section, teacher, teacher_role, :active),
      enrollment("enrollment-admin", course, section, admin, admin_role, :active),
      enrollment("enrollment-dropped", course, section, dropped_student, student_role, :dropped)
    ]

    %{
      student: student,
      teacher: teacher,
      admin: admin,
      outsider: outsider,
      dropped_student: dropped_student,
      course: course,
      roles: roles,
      enrollments: enrollments,
      modules: [module],
      pages: [page],
      files: [file],
      announcements: [
        %{
          id: "announcement-1",
          course_id: course.id,
          title: "Welcome to week one",
          message_html: "<p>Please review the syllabus.</p>",
          posted_at: "2027-01-10T16:00:00Z",
          status: :published
        }
      ],
      assignments: [assignment]
    }
  end

  def opts(fixture) do
    [
      courses: [fixture.course],
      roles: fixture.roles,
      enrollments: fixture.enrollments,
      modules: fixture.modules,
      pages: fixture.pages,
      files: fixture.files,
      announcements: fixture.announcements,
      assignments: fixture.assignments
    ]
  end

  defp user(id, sis_user_id, display_name) do
    User.new!(%{
      id: id,
      sis_user_id: sis_user_id,
      display_name: display_name,
      email: String.replace(sis_user_id, "sis-", "") <> "@example.edu",
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
