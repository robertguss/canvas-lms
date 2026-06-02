defmodule WtsLms.SchemaContractTest do
  use ExUnit.Case, async: true

  alias WtsLms.Schema
  alias WtsLms.Schema.{
    AcademicTerm,
    Account,
    Assignment,
    AssignmentGroup,
    ContentFile,
    Course,
    Enrollment,
    Grade,
    GradeItem,
    LearningModule,
    Notification,
    Page,
    Role,
    Section,
    Submission,
    User
  }

  test "core WTS coursework relationships are supported without Canvas operational clones" do
    account = Account.new!(%{name: "WTS", sis_account_id: "acct-1", legacy_canvas_id: "1"})
    term = AcademicTerm.new!(%{name: "Spring 2027", sis_term_id: "term-1", account_id: account.id, legacy_canvas_id: "10"})
    student_role = Role.new!(%{name: "Student", kind: :student, account_id: account.id})
    teacher_role = Role.new!(%{name: "Teacher", kind: :teacher, account_id: account.id})
    student = User.new!(%{sis_user_id: "stu-1", display_name: "Student One", email: "student@example.edu", role_ids: [student_role.id], legacy_canvas_id: "20"})
    teacher = User.new!(%{sis_user_id: "teach-1", display_name: "Teacher One", email: "teacher@example.edu", role_ids: [teacher_role.id], legacy_canvas_id: "21"})
    course = Course.new!(%{account_id: account.id, term_id: term.id, sis_course_id: "course-1", name: "Foundations", legacy_canvas_id: "30"})
    section = Section.new!(%{course_id: course.id, sis_section_id: "section-1", name: "A", legacy_canvas_id: "40"})
    student_enrollment = Enrollment.new!(%{course_id: course.id, section_id: section.id, user_id: student.id, role_id: student_role.id, state: :active, owner_system: :sis, legacy_canvas_id: "50"})
    teacher_enrollment = Enrollment.new!(%{course_id: course.id, section_id: section.id, user_id: teacher.id, role_id: teacher_role.id, state: :active, owner_system: :sis, legacy_canvas_id: "51"})
    module = LearningModule.new!(%{course_id: course.id, title: "Week 1", position: 1, legacy_canvas_id: "60"})
    page = Page.new!(%{course_id: course.id, module_id: module.id, title: "Welcome", slug: "welcome", body_html: "<p>Welcome</p>", legacy_canvas_id: "70"})
    file = ContentFile.new!(%{course_id: course.id, uploaded_by_user_id: teacher.id, display_name: "reading.pdf", storage_key: "course-1/reading.pdf", content_type: "application/pdf", byte_size: 1234, legacy_canvas_id: "80"})
    assignment_group = AssignmentGroup.new!(%{course_id: course.id, name: "Essays", weight: "40.0", legacy_canvas_id: "90"})
    assignment = Assignment.new!(%{course_id: course.id, assignment_group_id: assignment_group.id, title: "Reflection", submission_types: [:text_entry, :file_upload], points_possible: "10.0", legacy_canvas_id: "100"})
    submission = Submission.new!(%{assignment_id: assignment.id, user_id: student.id, enrollment_id: student_enrollment.id, attempt: 1, state: :submitted, body_html: "<p>Answer</p>", attachment_file_ids: [file.id], legacy_canvas_id: "110"})
    grade_item = GradeItem.new!(%{course_id: course.id, assignment_id: assignment.id, assignment_group_id: assignment_group.id, title: assignment.title, points_possible: assignment.points_possible})
    grade = Grade.new!(%{grade_item_id: grade_item.id, submission_id: submission.id, student_user_id: student.id, grader_user_id: teacher.id, points: "9.0", state: :posted, legacy_canvas_id: "120"})
    notification = Notification.new!(%{user_id: student.id, course_id: course.id, subject_type: :grade, subject_id: grade.id, channel: :email, state: :queued})

    assert Schema.clean_domain_tables() == [
             :accounts,
             :academic_terms,
             :users,
             :roles,
             :courses,
             :sections,
             :enrollments,
             :learning_modules,
             :pages,
             :content_files,
             :assignment_groups,
             :assignments,
             :submissions,
             :grade_items,
             :grades,
             :notifications,
             :legacy_mappings
           ]

    refute Enum.any?(Schema.clean_domain_tables(), &(to_string(&1) =~ ~r/^(canvas_|dap_)/))
    assert student_enrollment.owner_system == :sis
    assert teacher_enrollment.owner_system == :sis
    assert module.course_id == course.id
    assert page.module_id == module.id
    assert submission.attachment_file_ids == [file.id]
    assert grade.submission_id == submission.id
    assert notification.subject_type == :grade
  end

  test "importable schemas expose legacy Canvas mapping and audit fields" do
    for module <- Schema.importable_modules() do
      fields = module.fields()
      assert :legacy_canvas_id in fields, "#{inspect(module)} missing legacy_canvas_id"
      assert :source_system in fields, "#{inspect(module)} missing source_system"
      assert :import_batch_id in fields, "#{inspect(module)} missing import_batch_id"
      assert :last_imported_at in fields, "#{inspect(module)} missing last_imported_at"
      assert :source_updated_at in fields, "#{inspect(module)} missing source_updated_at"
    end
  end
end
