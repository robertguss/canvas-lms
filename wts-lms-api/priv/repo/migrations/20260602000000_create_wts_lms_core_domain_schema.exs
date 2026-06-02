defmodule WtsLms.Repo.Migrations.CreateWtsLmsCoreDomainSchema do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:name, :string, null: false)
      add(:sis_account_id, :string)
      add(:status, :string, null: false, default: "active")
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:academic_terms, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:account_id, :string, null: false)
      add(:name, :string, null: false)
      add(:sis_term_id, :string)
      add(:starts_at, :utc_datetime)
      add(:ends_at, :utc_datetime)
      add(:status, :string, null: false, default: "active")
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:users, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:sis_user_id, :string)
      add(:display_name, :string, null: false)
      add(:email, :string, null: false)
      add(:saml_name_id, :string)
      add(:status, :string, null: false, default: "active")
      add(:role_ids, {:array, :string}, null: false, default: [])
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:roles, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:account_id, :string, null: false)
      add(:name, :string, null: false)
      add(:kind, :string, null: false)
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:courses, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:account_id, :string, null: false)
      add(:term_id, :string, null: false)
      add(:sis_course_id, :string)
      add(:name, :string, null: false)
      add(:code, :string)
      add(:syllabus_html, :text)
      add(:status, :string, null: false, default: "active")
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:sections, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:course_id, :string, null: false)
      add(:sis_section_id, :string)
      add(:name, :string, null: false)
      add(:status, :string, null: false, default: "active")
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:enrollments, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:course_id, :string, null: false)
      add(:section_id, :string, null: false)
      add(:user_id, :string, null: false)
      add(:role_id, :string, null: false)
      add(:state, :string, null: false, default: "active")
      add(:owner_system, :string, null: false, default: "sis")
      add(:enrolled_at, :utc_datetime)
      add(:dropped_at, :utc_datetime)
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:learning_modules, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:course_id, :string, null: false)
      add(:title, :string, null: false)
      add(:position, :integer)
      add(:status, :string, null: false, default: "published")
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:pages, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:course_id, :string, null: false)
      add(:module_id, :string)
      add(:title, :string, null: false)
      add(:slug, :string, null: false)
      add(:body_html, :text)
      add(:status, :string, null: false, default: "published")
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:content_files, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:course_id, :string, null: false)
      add(:submission_id, :string)
      add(:uploaded_by_user_id, :string)
      add(:display_name, :string, null: false)
      add(:storage_key, :string, null: false)
      add(:content_type, :string)
      add(:byte_size, :bigint)
      add(:checksum, :string)
      add(:visibility, :string, null: false, default: "course")
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:assignment_groups, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:course_id, :string, null: false)
      add(:name, :string, null: false)
      add(:weight, :decimal)
      add(:position, :integer)
      add(:drop_rule, :map)
      add(:status, :string, null: false, default: "active")
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:assignments, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:course_id, :string, null: false)
      add(:assignment_group_id, :string)
      add(:title, :string, null: false)
      add(:description_html, :text)
      add(:submission_types, {:array, :string}, null: false, default: [])
      add(:points_possible, :decimal)
      add(:due_at, :utc_datetime)
      add(:available_at, :utc_datetime)
      add(:lock_at, :utc_datetime)
      add(:status, :string, null: false, default: "published")
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:submissions, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:assignment_id, :string, null: false)
      add(:user_id, :string, null: false)
      add(:enrollment_id, :string, null: false)
      add(:attempt, :integer, null: false, default: 1)
      add(:state, :string, null: false, default: "unsubmitted")
      add(:body_html, :text)
      add(:attachment_file_ids, {:array, :string}, null: false, default: [])
      add(:submitted_at, :utc_datetime)
      add(:late_at, :utc_datetime)
      add(:comments, {:array, :map}, null: false, default: [])
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:grade_items, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:course_id, :string, null: false)
      add(:assignment_id, :string)
      add(:assignment_group_id, :string)
      add(:title, :string, null: false)
      add(:points_possible, :decimal)
      add(:status, :string, null: false, default: "active")
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:grades, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:grade_item_id, :string, null: false)
      add(:submission_id, :string)
      add(:student_user_id, :string, null: false)
      add(:grader_user_id, :string)
      add(:points, :decimal)
      add(:state, :string, null: false, default: "unposted")
      add(:posted_at, :utc_datetime)
      add(:grading_comments, {:array, :map}, null: false, default: [])
      add(:audit_note, :text)
      add_legacy_fields()

      timestamps(type: :utc_datetime)
    end

    create table(:notifications, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:user_id, :string, null: false)
      add(:course_id, :string)
      add(:subject_type, :string, null: false)
      add(:subject_id, :string, null: false)
      add(:channel, :string, null: false, default: "email")
      add(:state, :string, null: false, default: "queued")
      add(:sent_at, :utc_datetime)

      timestamps(type: :utc_datetime)
    end

    create table(:legacy_mappings, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:entity_type, :string, null: false)
      add(:entity_id, :string, null: false)
      add(:source_system, :string, null: false)
      add(:legacy_canvas_id, :string, null: false)
      add(:import_batch_id, :string)
      add(:last_imported_at, :utc_datetime)
      add(:source_updated_at, :utc_datetime)

      timestamps(type: :utc_datetime)
    end

    create_legacy_indexes()

    create(
      unique_index(:legacy_mappings, [:source_system, :entity_type, :legacy_canvas_id],
        name: :unique_legacy_mapping_index
      )
    )
  end

  defp add_legacy_fields do
    add(:legacy_canvas_id, :string)
    add(:source_system, :string, null: false, default: "canvas")
    add(:import_batch_id, :string)
    add(:last_imported_at, :utc_datetime)
    add(:source_updated_at, :utc_datetime)
  end

  defp create_legacy_indexes do
    for table <- [
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
          :grades
        ] do
      create(
        index(table, [:source_system, :legacy_canvas_id],
          name: String.to_atom("#{table}_legacy_canvas_id_index")
        )
      )
    end
  end
end
