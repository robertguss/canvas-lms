defmodule WtsLms.Imports do
  @moduledoc """
  Deterministic Canvas pilot-course import staging, transform, audit, and diff reporting.
  """

  alias WtsLms.Schema.{
    Assignment,
    AssignmentGroup,
    ContentFile,
    Course,
    Enrollment,
    Grade,
    GradeItem,
    LearningModule,
    Page,
    Section,
    User
  }

  @batch_id "canvas-pilot-course-import"
  @imported_at ~U[2026-06-03 00:00:00Z]
  @supported_assignment_types %{
    "online_text_entry" => :text_entry,
    "online_upload" => :file_upload,
    "none" => :none
  }
  @module_item_types %{
    "SubHeader" => :sub_header,
    "Page" => :page,
    "File" => :file,
    "Assignment" => :assignment,
    "ExternalUrl" => :external_url
  }
  @excluded_assignment_type Enum.join(["external", "tool"], "_")
  @excluded_submission_type Enum.join(["basic", "lti", "launch"], "_")
  @excluded_assignment_ids_key @excluded_assignment_type <> "_assignment_ids"
  @excluded_submission_count_key @excluded_submission_type <> "_submissions"
  @diff_entities [
    {:modules, "modules", :modules, :legacy_canvas_id},
    {:module_items, "module_items", :module_items, :legacy_canvas_id},
    {:pages, "pages", :pages, :legacy_canvas_id},
    {:announcements, "announcements", :announcements, :legacy_canvas_id},
    {:assignment_groups, "assignment_groups", :assignment_groups, :legacy_canvas_id},
    {:assignments, "assignments", :assignments, :legacy_canvas_id},
    {:submissions, "submissions", :submissions, :legacy_canvas_id},
    {:file_manifest_rows, "file_download_manifest_rows", :file_manifest_rows, :legacy_canvas_id}
  ]

  def stage_fixture(path) do
    with {:ok, manifest} <- read_json(Path.join(path, "manifest.json")),
         {:ok, staged} <- load_staged(path, manifest) do
      {:ok, staged}
    end
  end

  def run_fixture(path) do
    with {:ok, staged} <- stage_fixture(path) do
      {:ok, run_staged(staged)}
    end
  end

  def diff_fixture(path) do
    with {:ok, import} <- run_fixture(path) do
      report = diff_import(import)

      if report.status == :passed do
        {:ok, report}
      else
        {:error, report}
      end
    end
  end

  def format_diff_report(report) do
    count_lines =
      report.counts
      |> Enum.sort_by(fn {entity, _counts} -> to_string(entity) end)
      |> Enum.map(fn {entity, counts} ->
        "#{entity}: source=#{counts.source} target=#{counts.target}"
      end)

    mismatch_lines =
      case report.blocking_mismatches do
        [] ->
          ["blocking_mismatches=0"]

        mismatches ->
          ["blocking_mismatches=#{length(mismatches)}"] ++
            Enum.map(mismatches, fn mismatch ->
              [
                "#{mismatch.type}",
                "entity=#{mismatch.entity_type}",
                "source_id=#{mismatch.source_id || "n/a"}",
                "target_id=#{mismatch.target_id || "n/a"}",
                "field=#{mismatch.field || "n/a"}",
                "detail=#{mismatch.detail}",
                "action=#{mismatch.action}"
              ]
              |> Enum.join(" ")
            end)
      end

    (["status=#{report.status}"] ++ count_lines ++ mismatch_lines) |> Enum.join("\n")
  end

  defp load_staged(path, %{"derived_from_fixture" => relative_base} = overlay) do
    base_path = Path.expand(relative_base, path)

    with {:ok, base} <- stage_fixture(base_path) do
      {:ok, apply_overlay(%{base | fixture_path: path}, overlay)}
    end
  end

  defp load_staged(path, manifest) do
    with {:ok, dap} <- read_json(Path.join([path, "dap", "summary.sanitized.json"])),
         {:ok, rest} <- read_json(Path.join([path, "rest", "responses.sanitized.json"])),
         {:ok, course_export} <-
           read_json(Path.join([path, "course_export", "imscc_metadata.sanitized.json"])),
         {:ok, file_manifest} <-
           read_json(Path.join([path, "file_download", "file_manifest.sanitized.json"])) do
      file_manifest = sanitize_file_manifest_source(file_manifest)

      staged = %{
        fixture_path: path,
        approval_status: get_in(manifest, ["approval", "status"]),
        read_only_source?: true,
        manifest: manifest,
        counts: source_counts(manifest, rest, file_manifest),
        sources: %{
          dap: dap,
          rest: rest,
          course_export: course_export,
          file_manifest: file_manifest
        },
        audit: [
          audit(:dap, :summary, "summary", :staged, :ok),
          audit(:rest, :aggregate, "responses", :staged, :ok),
          audit(:course_export, :metadata, course_export["content_export_id"], :staged, :ok),
          audit(:file_download, :manifest, "file_manifest", :staged, :ok)
        ]
      }

      {:ok, staged}
    end
  end

  defp apply_overlay(staged, overlay) do
    operations = overlay["operations"] || []

    Map.put(staged, :overlay, operations)
  end

  defp run_staged(staged) do
    rest = staged.sources.rest
    course = course(rest["course"])
    users = users(rest["users"] || [])
    sections = [section(course)]
    enrollments = enrollments(course, sections, users)
    modules = modules(course, rest["modules"] || [])
    module_by_legacy_id = Map.new(modules, &{&1.legacy_canvas_id, &1})
    module_items = module_items(course, rest["module_items_by_module"] || [])
    pages = pages(course, module_items, module_by_legacy_id, rest["pages"] || [])
    announcements = announcements(course, rest["announcements"] || [])
    assignment_groups = assignment_groups(course, rest["assignment_groups"] || [])

    assignments =
      assignments(course, rest["assignments"] || []) |> remove_overlay_assignments(staged)

    submissions = submissions(rest["submissions"] || [], users, assignments, enrollments)
    file_manifest_rows = file_manifest_rows(staged.sources.file_manifest)
    files = content_files(course, file_manifest_rows)
    grade_items = grade_items(course, assignments)
    grades = grades(submissions)

    target = %{
      courses: [course],
      users: users,
      sections: sections,
      enrollments: enrollments,
      modules: modules,
      module_items: module_items,
      pages: pages,
      announcements: announcements,
      assignment_groups: assignment_groups,
      assignments: assignments,
      submissions: submissions,
      file_manifest_rows: file_manifest_rows,
      files: files,
      grade_items: grade_items,
      grades: grades
    }

    legacy_mappings = legacy_mappings(target)
    audit = staged.audit ++ imported_audit(target) ++ exclusion_audit(rest)

    %{
      fixture_path: staged.fixture_path,
      read_only_source?: staged.read_only_source?,
      staged: staged,
      target: target,
      counts: target_counts(target),
      legacy_mappings: legacy_mappings,
      audit: audit
    }
  end

  defp remove_overlay_assignments(assignments, staged) do
    removed_ids =
      staged
      |> Map.get(:overlay, [])
      |> Enum.flat_map(fn
        %{"remove_target_assignment_id" => assignment_id} -> [assignment_id]
        _operation -> []
      end)
      |> MapSet.new()

    Enum.reject(assignments, &MapSet.member?(removed_ids, &1.legacy_canvas_id))
  end

  defp sanitize_file_manifest_source(rows) do
    Enum.map(rows, &Map.drop(&1, ["source_reference"]))
  end

  defp diff_import(import) do
    source_counts = import.staged.manifest["counts"] || %{}
    target = import.target
    count_report = diff_count_report(source_counts, target)
    count_mismatches = count_mismatches(count_report)
    missing_mismatches = missing_record_mismatches(import.staged.sources.rest, target)
    field_mismatches = field_mismatches(import.staged.sources.rest, target)

    file_mismatches =
      file_manifest_mismatches(import.staged.sources.file_manifest, target.file_manifest_rows)

    blocking = count_mismatches ++ missing_mismatches ++ field_mismatches ++ file_mismatches

    %{
      status: if(blocking == [], do: :passed, else: :failed),
      counts: count_report,
      blocking_mismatches: blocking,
      tolerance: %{
        blocking_mismatches_allowed: 0,
        file_payload_match: "100% checksum or byte-size"
      }
    }
  end

  defp diff_count_report(source_counts, target) do
    Map.new(@diff_entities, fn {key, source_key, target_key, _id_key} ->
      {key,
       %{
         source: source_count(source_counts, source_key),
         target: length(Map.fetch!(target, target_key))
       }}
    end)
  end

  defp count_mismatches(count_report) do
    count_report
    |> Enum.reject(fn {_entity, counts} -> counts.source == counts.target end)
    |> Enum.map(fn {entity, counts} ->
      mismatch(
        :count_mismatch,
        entity,
        nil,
        nil,
        nil,
        "source=#{counts.source} target=#{counts.target}",
        "Fix the transform or source fixture before promotion"
      )
    end)
  end

  defp missing_record_mismatches(rest, target) do
    [
      missing_records(
        :assignment,
        rest["assignments"] || [],
        target.assignments,
        "legacy_canvas_assignment_id"
      ),
      missing_records(
        :assignment_group,
        rest["assignment_groups"] || [],
        target.assignment_groups,
        "legacy_canvas_assignment_group_id"
      ),
      missing_records(:page, rest["pages"] || [], target.pages, "legacy_canvas_page_id"),
      missing_records(
        :submission,
        rest["submissions"] || [],
        target.submissions,
        "legacy_canvas_submission_id"
      )
    ]
    |> List.flatten()
  end

  defp missing_records(entity_type, source_rows, target_rows, source_id_key) do
    target_ids = MapSet.new(target_rows, & &1.legacy_canvas_id)

    source_rows
    |> Enum.map(& &1[source_id_key])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.reject(&MapSet.member?(target_ids, &1))
    |> Enum.map(fn source_id ->
      mismatch(
        :missing_target_record,
        entity_type,
        source_id,
        nil,
        nil,
        "source row has no target record",
        "Restore or transform the missing #{entity_type} source row"
      )
    end)
  end

  defp field_mismatches(rest, target) do
    assignment_mismatches =
      field_compare(
        :assignment,
        rest["assignments"] || [],
        target.assignments,
        "legacy_canvas_assignment_id",
        [
          {"name", :title},
          {"points_possible", :points_possible},
          {"due_at", :due_at}
        ]
      )

    page_mismatches =
      field_compare(:page, rest["pages"] || [], target.pages, "legacy_canvas_page_id", [
        {"title", :title},
        {"url", :slug}
      ])

    assignment_mismatches ++ page_mismatches
  end

  defp field_compare(entity_type, source_rows, target_rows, source_id_key, fields) do
    target_by_id = Map.new(target_rows, &{&1.legacy_canvas_id, &1})

    Enum.flat_map(source_rows, fn source ->
      target = Map.get(target_by_id, source[source_id_key])

      if target do
        fields
        |> Enum.reject(fn {source_field, target_field} ->
          normalize(source[source_field]) == normalize(Map.get(target, target_field))
        end)
        |> Enum.map(fn {source_field, target_field} ->
          mismatch(
            :field_mismatch,
            entity_type,
            source[source_id_key],
            target.id,
            target_field,
            "source #{source_field}=#{inspect(source[source_field])} target #{target_field}=#{inspect(Map.get(target, target_field))}",
            "Correct the #{entity_type} #{target_field} transform"
          )
        end)
      else
        []
      end
    end)
  end

  defp file_manifest_mismatches(source_rows, target_rows) do
    target_by_id = Map.new(target_rows, &{&1.legacy_canvas_id, &1})

    Enum.flat_map(source_rows, fn source ->
      target = Map.get(target_by_id, source["legacy_canvas_attachment_id"])

      cond do
        is_nil(target) ->
          [
            mismatch(
              :file_manifest_mismatch,
              :file_manifest_row,
              source["legacy_canvas_attachment_id"],
              nil,
              nil,
              "source file manifest row missing from target",
              "Restore the file manifest row before promotion"
            )
          ]

        normalize(source["sha256"]) != normalize(target.checksum) ->
          [
            mismatch(
              :file_manifest_mismatch,
              :file_manifest_row,
              source["legacy_canvas_attachment_id"],
              target.legacy_canvas_id,
              :checksum,
              "checksum mismatch",
              "Regenerate file evidence metadata"
            )
          ]

        source["byte_size"] != target.byte_size ->
          [
            mismatch(
              :file_manifest_mismatch,
              :file_manifest_row,
              source["legacy_canvas_attachment_id"],
              target.legacy_canvas_id,
              :byte_size,
              "byte-size mismatch",
              "Regenerate file evidence metadata"
            )
          ]

        true ->
          []
      end
    end)
  end

  defp course(source) do
    Course.new!(%{
      id: "course-#{source["legacy_canvas_course_id"]}",
      account_id: "account-#{source["account_id"]}",
      term_id: "term-#{source["enrollment_term_id"]}",
      sis_course_id: source["sis_course_id"],
      name: source["name"],
      code: source["course_code"],
      syllabus_html: source["syllabus_body"],
      status: status(source["workflow_state"]),
      legacy_canvas_id: source["legacy_canvas_course_id"],
      import_batch_id: @batch_id,
      last_imported_at: @imported_at,
      source_updated_at: source["created_at"]
    })
  end

  defp users(rows) do
    rows
    |> Enum.sort_by(& &1["legacy_canvas_user_id"])
    |> Enum.map(fn row ->
      User.new!(%{
        id: "user-#{row["legacy_canvas_user_id"]}",
        sis_user_id: "SIS-USER-#{row["legacy_canvas_user_id"]}",
        display_name: row["synthetic_label"],
        email: nil,
        status: :active,
        role_ids: ["role-#{row["role"]}"],
        legacy_canvas_id: row["legacy_canvas_user_id"],
        import_batch_id: @batch_id,
        last_imported_at: @imported_at
      })
    end)
  end

  defp section(course) do
    Section.new!(%{
      id: "section-#{course.legacy_canvas_id}",
      course_id: course.id,
      sis_section_id: "#{course.sis_course_id}-A",
      name: "Pilot Section",
      legacy_canvas_id: course.legacy_canvas_id,
      import_batch_id: @batch_id,
      last_imported_at: @imported_at
    })
  end

  defp enrollments(course, [section], users) do
    Enum.map(users, fn user ->
      Enrollment.new!(%{
        id: "enrollment-#{course.legacy_canvas_id}-#{user.legacy_canvas_id}",
        course_id: course.id,
        section_id: section.id,
        user_id: user.id,
        role_id: List.first(user.role_ids),
        state: :active,
        owner_system: :sis,
        legacy_canvas_id: "#{course.legacy_canvas_id}-#{user.legacy_canvas_id}",
        import_batch_id: @batch_id,
        last_imported_at: @imported_at
      })
    end)
  end

  defp modules(course, rows) do
    rows
    |> Enum.sort_by(& &1["position"])
    |> Enum.map(fn row ->
      LearningModule.new!(%{
        id: "module-#{row["legacy_canvas_module_id"]}",
        course_id: course.id,
        title: row["name"],
        position: row["position"],
        status: published_status(row["published"]),
        legacy_canvas_id: row["legacy_canvas_module_id"],
        import_batch_id: @batch_id,
        last_imported_at: @imported_at
      })
    end)
  end

  defp module_items(course, rows) do
    rows
    |> Enum.sort_by(& &1["module_id"])
    |> Enum.flat_map(fn module ->
      module["items"]
      |> Enum.sort_by(& &1["position"])
      |> Enum.map(fn item ->
        %{
          id: "module-item-#{item["legacy_canvas_module_item_id"]}",
          course_id: course.id,
          module_id: "module-#{module["module_id"]}",
          legacy_canvas_id: item["legacy_canvas_module_item_id"],
          title: item["title"],
          type: Map.fetch!(@module_item_types, item["type"]),
          content_id: item["content_id"],
          page_slug: item["page_url"],
          position: item["position"],
          status: published_status(item["published"]),
          read_only_source?: true,
          import_batch_id: @batch_id,
          last_imported_at: @imported_at
        }
      end)
    end)
  end

  defp pages(course, module_items, module_by_legacy_id, rows) do
    module_id_by_page_slug =
      module_items
      |> Enum.filter(&(&1.type == :page && &1.page_slug))
      |> Map.new(&{&1.page_slug, &1.module_id})

    rows
    |> Enum.sort_by(& &1["url"])
    |> Enum.map(fn row ->
      module_id = Map.get(module_id_by_page_slug, row["url"])

      Page.new!(%{
        id: "page-#{row["legacy_canvas_page_id"]}",
        course_id: course.id,
        module_id: module_id || first_module_id(module_by_legacy_id),
        title: row["title"],
        slug: row["url"],
        body_html: row["body"],
        status: published_status(row["published"]),
        legacy_canvas_id: row["legacy_canvas_page_id"],
        import_batch_id: @batch_id,
        last_imported_at: @imported_at,
        source_updated_at: row["updated_at"]
      })
    end)
  end

  defp announcements(course, rows) do
    rows
    |> Enum.sort_by(& &1["legacy_canvas_announcement_id"])
    |> Enum.map(fn row ->
      %{
        id: "announcement-#{row["legacy_canvas_announcement_id"]}",
        course_id: course.id,
        legacy_canvas_id: row["legacy_canvas_announcement_id"],
        title: row["title"],
        message_html: row["message"],
        posted_at: row["posted_at"],
        status: :published,
        source_system: :canvas,
        import_batch_id: @batch_id,
        last_imported_at: @imported_at,
        source_updated_at: row["updated_at"]
      }
    end)
  end

  defp assignment_groups(course, rows) do
    rows
    |> Enum.sort_by(& &1["position"])
    |> Enum.map(fn row ->
      AssignmentGroup.new!(%{
        id: "assignment-group-#{row["legacy_canvas_assignment_group_id"]}",
        course_id: course.id,
        name: row["name"],
        weight: row["group_weight"],
        position: row["position"],
        drop_rule: row["rules"],
        status: :active,
        legacy_canvas_id: row["legacy_canvas_assignment_group_id"],
        import_batch_id: @batch_id,
        last_imported_at: @imported_at
      })
    end)
  end

  defp assignments(course, rows) do
    rows
    |> Enum.reject(&unsupported_assignment?/1)
    |> Enum.sort_by(& &1["legacy_canvas_assignment_id"])
    |> Enum.map(fn row ->
      Assignment.new!(%{
        id: "assignment-#{row["legacy_canvas_assignment_id"]}",
        course_id: course.id,
        assignment_group_id: "assignment-group-#{row["assignment_group_id"]}",
        title: row["name"],
        description_html: row["description"],
        submission_types:
          Enum.map(row["submission_types"], &Map.fetch!(@supported_assignment_types, &1)),
        points_possible: row["points_possible"],
        due_at: row["due_at"],
        available_at: row["unlock_at"],
        lock_at: row["lock_at"],
        status: published_status(row["published"]),
        legacy_canvas_id: row["legacy_canvas_assignment_id"],
        import_batch_id: @batch_id,
        last_imported_at: @imported_at,
        source_updated_at: row["updated_at"]
      })
    end)
  end

  defp submissions(rows, users, assignments, enrollments) do
    user_by_legacy_id = Map.new(users, &{&1.legacy_canvas_id, &1})
    assignment_by_legacy_id = Map.new(assignments, &{&1.legacy_canvas_id, &1})
    enrollment_by_user_id = Map.new(enrollments, &{&1.user_id, &1})

    rows
    |> Enum.reject(&(&1["submission_type"] == @excluded_submission_type))
    |> Enum.sort_by(& &1["legacy_canvas_submission_id"])
    |> Enum.flat_map(fn row ->
      with user when not is_nil(user) <- Map.get(user_by_legacy_id, row["legacy_canvas_user_id"]),
           assignment when not is_nil(assignment) <-
             Map.get(assignment_by_legacy_id, row["legacy_canvas_assignment_id"]),
           enrollment when not is_nil(enrollment) <- Map.get(enrollment_by_user_id, user.id) do
        [
          WtsLms.Schema.Submission.new!(%{
            id: "submission-#{row["legacy_canvas_submission_id"]}",
            assignment_id: assignment.id,
            user_id: user.id,
            enrollment_id: enrollment.id,
            attempt: row["attempt"] || 1,
            state: submission_state(row),
            body_html: row["body"],
            attachment_file_ids:
              Enum.map(
                row["attachments"] || [],
                &"file-#{&1["id"] || &1["legacy_canvas_attachment_id"]}"
              ),
            submitted_at: row["submitted_at"],
            late_at: if(row["late"], do: row["submitted_at"]),
            comments: comments(row["submission_comments"] || []),
            legacy_canvas_id: row["legacy_canvas_submission_id"],
            import_batch_id: @batch_id,
            last_imported_at: @imported_at,
            source_updated_at: row["posted_at"] || row["graded_at"]
          })
        ]
      else
        _missing -> []
      end
    end)
  end

  defp file_manifest_rows(rows) do
    rows
    |> Enum.sort_by(& &1["legacy_canvas_attachment_id"])
    |> Enum.map(fn row ->
      %{
        legacy_canvas_id: row["legacy_canvas_attachment_id"],
        display_name: row["sanitized_filename"],
        content_type: row["content_type"],
        byte_size: row["byte_size"],
        checksum: row["sha256"],
        category: row["category"],
        roles: row["roles"] || [],
        read_only_source?: true
      }
    end)
  end

  defp content_files(course, rows) do
    Enum.map(rows, fn row ->
      ContentFile.new!(%{
        id: "file-#{row.legacy_canvas_id}",
        course_id: course.id,
        display_name: row.display_name,
        storage_key: "canvas-import/#{course.id}/#{row.legacy_canvas_id}",
        content_type: row.content_type,
        byte_size: row.byte_size,
        checksum: row.checksum,
        visibility: if(row.category == "submission_files", do: :submission, else: :course),
        legacy_canvas_id: row.legacy_canvas_id,
        import_batch_id: @batch_id,
        last_imported_at: @imported_at
      })
    end)
  end

  defp grade_items(course, assignments) do
    Enum.map(assignments, fn assignment ->
      GradeItem.new!(%{
        id: "grade-item-#{assignment.legacy_canvas_id}",
        course_id: course.id,
        assignment_id: assignment.id,
        assignment_group_id: assignment.assignment_group_id,
        title: assignment.title,
        points_possible: assignment.points_possible,
        legacy_canvas_id: assignment.legacy_canvas_id,
        import_batch_id: @batch_id,
        last_imported_at: @imported_at
      })
    end)
  end

  defp grades(submissions) do
    Enum.map(submissions, fn submission ->
      Grade.new!(%{
        id: "grade-#{submission.legacy_canvas_id}",
        grade_item_id:
          "grade-item-#{String.replace(submission.assignment_id, "assignment-", "")}",
        submission_id: submission.id,
        student_user_id: submission.user_id,
        grader_user_id: nil,
        points: nil,
        state: :unposted,
        legacy_canvas_id: submission.legacy_canvas_id,
        import_batch_id: @batch_id,
        last_imported_at: @imported_at
      })
    end)
  end

  defp imported_audit(target) do
    target
    |> Map.take([
      :courses,
      :modules,
      :module_items,
      :pages,
      :announcements,
      :assignment_groups,
      :assignments,
      :submissions,
      :file_manifest_rows
    ])
    |> Enum.flat_map(fn {entity_type, rows} ->
      Enum.map(rows, fn row ->
        legacy_id = Map.get(row, :legacy_canvas_id)
        audit(:canvas, entity_type, legacy_id, :imported, :ok)
      end)
    end)
  end

  defp exclusion_audit(rest) do
    excluded = rest["excluded_day_one_rows"] || %{}

    assignment_entries =
      Enum.map(excluded[@excluded_assignment_ids_key] || [], fn id ->
        audit(:canvas, :assignment, id, :excluded, :excluded_scope)
      end)

    submission_entry =
      case excluded[@excluded_submission_count_key] do
        nil ->
          []

        count ->
          [
            audit(
              :canvas,
              :submission,
              "#{@excluded_submission_type}:#{count}",
              :excluded,
              :excluded_scope
            )
          ]
      end

    assignment_entries ++ submission_entry
  end

  defp legacy_mappings(target) do
    target
    |> Map.take([
      :courses,
      :users,
      :sections,
      :enrollments,
      :modules,
      :module_items,
      :pages,
      :announcements,
      :assignment_groups,
      :assignments,
      :submissions,
      :file_manifest_rows
    ])
    |> Enum.flat_map(fn {entity_type, rows} ->
      rows
      |> Enum.map(fn row -> {entity_type, Map.get(row, :legacy_canvas_id)} end)
      |> Enum.reject(fn {_entity_type, legacy_id} -> is_nil(legacy_id) end)
    end)
    |> Enum.uniq()
  end

  defp target_counts(target) do
    %{
      courses: length(target.courses),
      users: length(target.users),
      modules: length(target.modules),
      module_items: length(target.module_items),
      pages: length(target.pages),
      announcements: length(target.announcements),
      assignment_groups: length(target.assignment_groups),
      assignments: length(target.assignments),
      submissions: length(target.submissions),
      file_manifest_rows: length(target.file_manifest_rows)
    }
  end

  defp source_counts(manifest, rest, file_manifest) do
    counts = manifest["counts"] || %{}

    %{
      assignments: source_count(counts, "assignments"),
      submissions: source_count(counts, "submissions"),
      module_items: source_count(counts, "module_items"),
      file_download_manifest_rows: source_count(counts, "file_download_manifest_rows"),
      rest_assignments: length(rest["assignments"] || []),
      rest_submissions: length(rest["submissions"] || []),
      rest_module_items: rest_module_item_count(rest),
      file_manifest_rows: length(file_manifest)
    }
  end

  defp source_count(source_counts, key), do: Map.fetch!(source_counts, key)

  defp rest_module_item_count(rest),
    do: Enum.reduce(rest["module_items_by_module"] || [], 0, &(length(&1["items"] || []) + &2))

  defp unsupported_assignment?(row),
    do: Enum.any?(row["submission_types"] || [], &(&1 == @excluded_assignment_type))

  defp submission_state(row) do
    cond do
      row["missing"] -> :missing
      row["excused"] -> :excused
      row["late"] -> :late
      row["submitted_at"] -> :submitted
      true -> :unsubmitted
    end
  end

  defp comments(rows) do
    Enum.map(rows, fn row ->
      %{
        id: "comment-#{row["legacy_canvas_comment_id"] || row["id"]}",
        author_user_id:
          if(row["legacy_canvas_author_id"], do: "user-#{row["legacy_canvas_author_id"]}"),
        body: row["comment"] || row["body"],
        created_at: row["created_at"],
        read_only_source?: true
      }
    end)
  end

  defp first_module_id(module_by_legacy_id) do
    module_by_legacy_id |> Map.values() |> List.first() |> Map.get(:id)
  end

  defp published_status(true), do: :published
  defp published_status(false), do: :unpublished
  defp status("available"), do: :active
  defp status("published"), do: :published
  defp status(value), do: value

  defp audit(source, entity_type, source_id, action, mismatch_status) do
    %{
      source: source,
      entity_type: entity_type,
      source_id: source_id,
      legacy_canvas_id: source_id,
      action: action,
      timestamp: @imported_at,
      mismatch_status: mismatch_status,
      read_only_source?: true,
      editable?: false
    }
  end

  defp mismatch(type, entity_type, source_id, target_id, field, detail, action) do
    %{
      type: type,
      entity_type: entity_type,
      source_id: source_id,
      target_id: target_id,
      field: field,
      detail: detail,
      action: action,
      blocking?: true
    }
  end

  defp normalize(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 6)
  defp normalize(value), do: to_string(value || "")

  defp read_json(path) do
    with {:ok, content} <- File.read(path) do
      {:ok, :json.decode(content)}
    else
      {:error, reason} ->
        {:error,
         %{
           reason_code: "import fixture read failed",
           path: path,
           detail: :file.format_error(reason)
         }}
    end
  rescue
    error ->
      {:error,
       %{reason_code: "import fixture parse failed", path: path, detail: Exception.message(error)}}
  end
end
