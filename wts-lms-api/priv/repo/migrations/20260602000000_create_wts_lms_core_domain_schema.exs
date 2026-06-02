defmodule WtsLms.Repo.Migrations.CreateWtsLmsCoreDomainSchema do
  @moduledoc """
  Migration manifest for the clean WTS LMS Phoenix domain schema.

  This scaffold is dependency-free until the real Repo/adapter decision lands,
  so the file records the Ecto migration contract deterministically. When Ecto
  SQL is introduced, these table definitions should become `create table(...)`
  statements with the same names, fields, foreign keys, and indexes.
  """

  @legacy_fields [:legacy_canvas_id, :source_system, :import_batch_id, :last_imported_at, :source_updated_at]

  @tables [
    accounts: [:name, :sis_account_id, :status] ++ @legacy_fields,
    academic_terms: [:account_id, :name, :sis_term_id, :starts_at, :ends_at, :status] ++ @legacy_fields,
    users: [:sis_user_id, :display_name, :email, :saml_name_id, :status, :role_ids] ++ @legacy_fields,
    roles: [:account_id, :name, :kind] ++ @legacy_fields,
    courses: [:account_id, :term_id, :sis_course_id, :name, :code, :syllabus_html, :status] ++ @legacy_fields,
    sections: [:course_id, :sis_section_id, :name, :status] ++ @legacy_fields,
    enrollments: [:course_id, :section_id, :user_id, :role_id, :state, :owner_system, :enrolled_at, :dropped_at] ++ @legacy_fields,
    learning_modules: [:course_id, :title, :position, :status] ++ @legacy_fields,
    pages: [:course_id, :module_id, :title, :slug, :body_html, :status] ++ @legacy_fields,
    content_files: [:course_id, :submission_id, :uploaded_by_user_id, :display_name, :storage_key, :content_type, :byte_size, :checksum, :visibility] ++ @legacy_fields,
    assignment_groups: [:course_id, :name, :weight, :position, :drop_rule, :status] ++ @legacy_fields,
    assignments: [:course_id, :assignment_group_id, :title, :description_html, :submission_types, :points_possible, :due_at, :available_at, :lock_at, :status] ++ @legacy_fields,
    submissions: [:assignment_id, :user_id, :enrollment_id, :attempt, :state, :body_html, :attachment_file_ids, :submitted_at, :late_at, :comments] ++ @legacy_fields,
    grade_items: [:course_id, :assignment_id, :assignment_group_id, :title, :points_possible, :status] ++ @legacy_fields,
    grades: [:grade_item_id, :submission_id, :student_user_id, :grader_user_id, :points, :state, :posted_at, :grading_comments, :audit_note] ++ @legacy_fields,
    notifications: [:user_id, :course_id, :subject_type, :subject_id, :channel, :state, :sent_at],
    legacy_mappings: [:entity_type, :entity_id, :source_system, :legacy_canvas_id, :import_batch_id, :last_imported_at, :source_updated_at]
  ]

  @indexes [
    unique_legacy_mapping_index: [:legacy_mappings, [:source_system, :entity_type, :legacy_canvas_id]],
    accounts_legacy_canvas_id_index: [:accounts, [:source_system, :legacy_canvas_id]],
    academic_terms_legacy_canvas_id_index: [:academic_terms, [:source_system, :legacy_canvas_id]],
    users_legacy_canvas_id_index: [:users, [:source_system, :legacy_canvas_id]],
    roles_legacy_canvas_id_index: [:roles, [:source_system, :legacy_canvas_id]],
    courses_legacy_canvas_id_index: [:courses, [:source_system, :legacy_canvas_id]],
    sections_legacy_canvas_id_index: [:sections, [:source_system, :legacy_canvas_id]],
    enrollments_legacy_canvas_id_index: [:enrollments, [:source_system, :legacy_canvas_id]],
    learning_modules_legacy_canvas_id_index: [:learning_modules, [:source_system, :legacy_canvas_id]],
    pages_legacy_canvas_id_index: [:pages, [:source_system, :legacy_canvas_id]],
    content_files_legacy_canvas_id_index: [:content_files, [:source_system, :legacy_canvas_id]],
    assignment_groups_legacy_canvas_id_index: [:assignment_groups, [:source_system, :legacy_canvas_id]],
    assignments_legacy_canvas_id_index: [:assignments, [:source_system, :legacy_canvas_id]],
    submissions_legacy_canvas_id_index: [:submissions, [:source_system, :legacy_canvas_id]],
    grade_items_legacy_canvas_id_index: [:grade_items, [:source_system, :legacy_canvas_id]],
    grades_legacy_canvas_id_index: [:grades, [:source_system, :legacy_canvas_id]]
  ]

  def tables, do: @tables
  def indexes, do: @indexes
end
