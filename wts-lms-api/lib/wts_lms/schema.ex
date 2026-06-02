defmodule WtsLms.Schema.Entity do
  @moduledoc false

  @audit_fields [:legacy_canvas_id, :source_system, :import_batch_id, :last_imported_at, :source_updated_at]
  @timestamps [:inserted_at, :updated_at]

  defmacro __using__(opts) do
    fields = Keyword.fetch!(opts, :fields)
    defaults = Keyword.get(opts, :defaults, [])
    importable? = Keyword.get(opts, :importable?, true)
    all_fields = [:id] ++ fields ++ @audit_fields ++ @timestamps
    default_pairs = Enum.map(all_fields, &{&1, Keyword.get(defaults, &1)})

    quote bind_quoted: [all_fields: all_fields, default_pairs: default_pairs, importable?: importable?] do
      @fields all_fields
      @importable? importable?
      defstruct default_pairs

      def fields, do: @fields
      def importable?, do: @importable?

      def new!(attrs) when is_map(attrs) do
        attrs = Map.new(attrs)
        now = Map.get(attrs, :inserted_at) || DateTime.utc_now() |> DateTime.truncate(:second)

        attrs =
          attrs
          |> Map.put_new(:id, generated_id(__MODULE__, attrs))
          |> Map.put_new(:source_system, :canvas)
          |> Map.put_new(:inserted_at, now)
          |> Map.put_new(:updated_at, now)

        struct!(__MODULE__, attrs)
      end

      defp generated_id(module, attrs) do
        source = Enum.find_value([:sis_user_id, :sis_course_id, :sis_section_id, :sis_term_id, :legacy_canvas_id, :name, :title], fn key -> Map.get(attrs, key) end)
        base = module |> Module.split() |> List.last() |> Macro.underscore()
        suffix = source || System.unique_integer([:positive])
        base <> "-" <> to_string(suffix)
      end
    end
  end
end

defmodule WtsLms.Schema.Account do
  use WtsLms.Schema.Entity, fields: [:name, :sis_account_id, :status], defaults: [status: :active]
end

defmodule WtsLms.Schema.AcademicTerm do
  use WtsLms.Schema.Entity, fields: [:account_id, :name, :sis_term_id, :starts_at, :ends_at, :status], defaults: [status: :active]
end

defmodule WtsLms.Schema.Role do
  use WtsLms.Schema.Entity, fields: [:account_id, :name, :kind], defaults: [source_system: :sis]
end

defmodule WtsLms.Schema.User do
  use WtsLms.Schema.Entity,
    fields: [:sis_user_id, :display_name, :email, :saml_name_id, :status, :role_ids],
    defaults: [status: :active, role_ids: [], source_system: :sis]
end

defmodule WtsLms.Schema.Course do
  use WtsLms.Schema.Entity,
    fields: [:account_id, :term_id, :sis_course_id, :name, :code, :syllabus_html, :status],
    defaults: [status: :active, source_system: :sis]
end

defmodule WtsLms.Schema.Section do
  use WtsLms.Schema.Entity,
    fields: [:course_id, :sis_section_id, :name, :status],
    defaults: [status: :active, source_system: :sis]
end

defmodule WtsLms.Schema.Enrollment do
  use WtsLms.Schema.Entity,
    fields: [:course_id, :section_id, :user_id, :role_id, :state, :owner_system, :enrolled_at, :dropped_at],
    defaults: [state: :active, owner_system: :sis, source_system: :sis]
end

defmodule WtsLms.Schema.LearningModule do
  use WtsLms.Schema.Entity,
    fields: [:course_id, :title, :position, :status],
    defaults: [status: :published]
end

defmodule WtsLms.Schema.Page do
  use WtsLms.Schema.Entity,
    fields: [:course_id, :module_id, :title, :slug, :body_html, :status],
    defaults: [status: :published]
end

defmodule WtsLms.Schema.ContentFile do
  use WtsLms.Schema.Entity,
    fields: [:course_id, :submission_id, :uploaded_by_user_id, :display_name, :storage_key, :content_type, :byte_size, :checksum, :visibility],
    defaults: [visibility: :course]
end

defmodule WtsLms.Schema.AssignmentGroup do
  use WtsLms.Schema.Entity,
    fields: [:course_id, :name, :weight, :position, :drop_rule, :status],
    defaults: [status: :active]
end

defmodule WtsLms.Schema.Assignment do
  use WtsLms.Schema.Entity,
    fields: [:course_id, :assignment_group_id, :title, :description_html, :submission_types, :points_possible, :due_at, :available_at, :lock_at, :status],
    defaults: [submission_types: [], status: :published]
end

defmodule WtsLms.Schema.Submission do
  use WtsLms.Schema.Entity,
    fields: [:assignment_id, :user_id, :enrollment_id, :attempt, :state, :body_html, :attachment_file_ids, :submitted_at, :late_at, :comments],
    defaults: [attempt: 1, state: :unsubmitted, attachment_file_ids: [], comments: []]
end

defmodule WtsLms.Schema.GradeItem do
  use WtsLms.Schema.Entity,
    fields: [:course_id, :assignment_id, :assignment_group_id, :title, :points_possible, :status],
    defaults: [status: :active]
end

defmodule WtsLms.Schema.Grade do
  use WtsLms.Schema.Entity,
    fields: [:grade_item_id, :submission_id, :student_user_id, :grader_user_id, :points, :state, :posted_at, :grading_comments, :audit_note],
    defaults: [state: :unposted, grading_comments: []]
end

defmodule WtsLms.Schema.Notification do
  use WtsLms.Schema.Entity,
    fields: [:user_id, :course_id, :subject_type, :subject_id, :channel, :state, :sent_at],
    defaults: [channel: :email, state: :queued],
    importable?: false
end

defmodule WtsLms.Schema do
  @moduledoc """
  Clean WTS LMS domain schema manifest for the Phoenix replacement scaffold.

  The modules model WTS academic identity, coursework content, assignments,
  submissions, files, grades, notifications, and import metadata. Canvas is kept
  at the boundary through `legacy_canvas_id`, `source_system`, and audit fields;
  operational Canvas or DAP table names are intentionally not part of the domain
  table list.
  """

  @modules [
    WtsLms.Schema.Account,
    WtsLms.Schema.AcademicTerm,
    WtsLms.Schema.User,
    WtsLms.Schema.Role,
    WtsLms.Schema.Course,
    WtsLms.Schema.Section,
    WtsLms.Schema.Enrollment,
    WtsLms.Schema.LearningModule,
    WtsLms.Schema.Page,
    WtsLms.Schema.ContentFile,
    WtsLms.Schema.AssignmentGroup,
    WtsLms.Schema.Assignment,
    WtsLms.Schema.Submission,
    WtsLms.Schema.GradeItem,
    WtsLms.Schema.Grade,
    WtsLms.Schema.Notification
  ]

  @domain_tables [
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

  def modules, do: @modules
  def clean_domain_tables, do: @domain_tables
  def importable_modules, do: Enum.filter(@modules, & &1.importable?())
end
