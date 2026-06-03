defmodule WtsLms.FilesTest do
  use ExUnit.Case, async: true

  alias WtsLms.Files
  alias WtsLms.Schema.{ContentFile, Course, Enrollment, Role, Section, User}

  @now ~U[2027-01-12 15:30:00Z]

  test "authorized upload URL minting validates metadata before exposing object reference" do
    fixture = fixture()

    assert {:ok, result} =
             Files.request_upload_url(
               fixture.course.id,
               fixture.student,
               %{
                 display_name: "../notes.pdf",
                 content_type: "application/pdf",
                 byte_size: 500_000,
                 checksum: "sha256-notes"
               },
               opts(fixture)
             )

    assert result.file.display_name == "notes.pdf"
    assert result.file.byte_size == 500_000
    assert result.file.storage_key == "course-1/student-1/notes.pdf"
    assert result.upload.method == :put
    assert result.upload.expires_at == ~U[2027-01-12 15:45:00Z]

    assert result.upload.headers == %{
             "Content-Type" => "application/pdf",
             "x-amz-checksum-sha256" => "sha256-notes"
           }

    assert result.upload.object_ref =~ "obj_"
    assert result.upload.url =~ "https://storage.example.invalid/wts-lms-test/obj_"
    refute result.upload.url =~ result.file.storage_key
  end

  test "authorized download URL minting keeps storage key opaque" do
    fixture = fixture()

    assert {:ok, result} = Files.download_url(fixture.file.id, fixture.student, opts(fixture))

    assert result.file.id == fixture.file.id
    assert result.download.method == :get
    assert result.download.expires_at == ~U[2027-01-12 15:45:00Z]
    assert result.download.object_ref =~ "obj_"
    refute result.download.url =~ fixture.file.storage_key
    refute result.download.url =~ "course-1/private"
  end

  test "unauthorized download returns 403-like result without object URL" do
    fixture = fixture()

    assert {:error, error} = Files.download_url(fixture.file.id, fixture.outsider, opts(fixture))

    assert error.status == 403
    assert error.reason_code == "file download forbidden"
    assert error.object_url == nil
  end

  test "missing file returns actionable error without object URL" do
    fixture = fixture()

    assert {:error, error} = Files.download_url("missing-file", fixture.student, opts(fixture))

    assert error.status == 404
    assert error.reason_code == "file missing"
    assert error.action == "ask the instructor to re-upload the file or contact support"
    assert error.object_url == nil
  end

  test "large file metadata is rejected deterministically before URL minting" do
    fixture = fixture()

    assert {:error, error} =
             Files.request_upload_url(
               fixture.course.id,
               fixture.student,
               %{
                 display_name: "huge.mov",
                 content_type: "video/quicktime",
                 byte_size: 1_000_001,
                 checksum: "sha256-huge"
               },
               opts(fixture)
             )

    assert error.status == 413
    assert error.reason_code == "file too large"
    assert error.max_upload_bytes == 1_000_000
    assert error.object_url == nil
  end

  defp fixture do
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
      roles: [student_role],
      enrollments: [enrollment],
      file: file
    }
  end

  defp opts(fixture) do
    [
      courses: [fixture.course],
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
