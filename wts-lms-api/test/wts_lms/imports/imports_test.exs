defmodule WtsLms.ImportsTest do
  use ExUnit.Case, async: true

  alias WtsLms.Imports

  @fixture Path.expand("../../fixtures/canvas_sample/pilot_course", __DIR__)
  @missing_assignment_fixture Path.expand(
                                "../../fixtures/canvas_sample/pilot_course_missing_assignment",
                                __DIR__
                              )

  test "fixture staging loads every approved sanitized source component" do
    assert {:ok, staged} = Imports.stage_fixture(@fixture)

    assert staged.fixture_path == @fixture
    assert staged.approval_status == "approved"
    assert staged.read_only_source? == true
    assert staged.counts.assignments == 13
    assert staged.counts.submissions == 390
    assert staged.counts.module_items == 134
    assert staged.counts.file_download_manifest_rows == 83
    assert staged.sources.dap["payload_kind"] == "dap_baseline_summary_not_full_table_extract"
    assert staged.sources.rest["course"]["legacy_canvas_course_id"] == 4363
    assert staged.sources.course_export["package_entry_count"] == 224
    assert length(staged.sources.file_manifest) == 83

    assert Enum.all?(staged.audit, &(&1.read_only_source? == true))
    refute inspect(staged) =~ "access_token"
    refute inspect(staged) =~ "Authorization"
    refute inspect(staged) =~ "private_evidence"
  end

  test "transform produces domain-shaped target records for day-one Canvas coursework" do
    assert {:ok, import} = Imports.run_fixture(@fixture)

    assert length(import.target.courses) == 1
    assert length(import.target.modules) == 16
    assert length(import.target.module_items) == 134
    assert length(import.target.pages) == 80
    assert length(import.target.announcements) == 12
    assert length(import.target.assignment_groups) == 4
    assert length(import.target.assignments) == 13
    assert length(import.target.submissions) == 390
    assert length(import.target.file_manifest_rows) == 83

    assignment = hd(import.target.assignments)
    assert assignment.id =~ "assignment-"
    assert assignment.source_system == :canvas
    assert assignment.legacy_canvas_id
    assert assignment.submission_types -- [:text_entry, :file_upload, :none] == []

    assert Enum.all?(
             import.target.module_items,
             &(&1.type in [:sub_header, :page, :file, :assignment, :external_url])
           )

    assert Enum.any?(import.target.submissions, &(length(&1.comments) > 0))
  end

  test "file manifest rows retain checksum and byte-size metadata without private source references" do
    assert {:ok, import} = Imports.run_fixture(@fixture)

    first_row = hd(import.target.file_manifest_rows)

    assert Map.keys(first_row) |> Enum.sort() == [
             :byte_size,
             :category,
             :checksum,
             :content_type,
             :display_name,
             :legacy_canvas_id,
             :read_only_source?,
             :roles
           ]

    assert is_integer(first_row.byte_size)
    assert byte_size(first_row.checksum) == 64
    refute Map.has_key?(first_row, :source_reference)
    refute inspect(import.target.file_manifest_rows) =~ "private_evidence"
  end

  test "idempotent re-runs return stable counts and no duplicate legacy mappings" do
    assert {:ok, first} = Imports.run_fixture(@fixture)
    assert {:ok, second} = Imports.run_fixture(@fixture)

    assert first.counts == second.counts
    assert length(first.audit) == length(second.audit)
    assert Enum.sort(first.legacy_mappings) == Enum.sort(second.legacy_mappings)
    assert length(first.legacy_mappings) == length(Enum.uniq(first.legacy_mappings))
  end

  test "diff succeeds for approved fixture with zero blocking mismatches" do
    assert {:ok, report} = Imports.diff_fixture(@fixture)

    assert report.status == :passed
    assert report.blocking_mismatches == []
    assert report.counts.assignments == %{source: 13, target: 13}
    assert report.counts.file_manifest_rows == %{source: 83, target: 83}
  end

  test "diff fails for a deliberate missing assignment with an actionable report" do
    assert {:error, report} = Imports.diff_fixture(@missing_assignment_fixture)

    assert report.status == :failed
    assert report.counts.assignments == %{source: 13, target: 12}

    assert Enum.any?(report.blocking_mismatches, fn mismatch ->
             mismatch.type == :missing_target_record and mismatch.entity_type == :assignment and
               mismatch.source_id == 83856 and mismatch.action =~ "Restore or transform"
           end)
  end

  test "archived source rows are represented as read-only import and audit metadata" do
    assert {:ok, import} = Imports.run_fixture(@fixture)

    assert import.read_only_source? == true
    assert Enum.all?(import.audit, &(&1.read_only_source? == true))
    assert Enum.all?(import.audit, &(&1.editable? == false))
    assert Enum.any?(import.audit, &(&1.action == :excluded))
  end

  test "day-one source exclusions prevent LTI and external tool rows from reappearing" do
    assert {:ok, import} = Imports.run_fixture(@fixture)

    refute inspect(import.target.assignments) =~ "external_tool"
    refute inspect(import.target.submissions) =~ "basic_lti"

    assert Enum.any?(import.audit, fn entry ->
             entry.action == :excluded and entry.entity_type == :assignment and
               entry.mismatch_status == :excluded_scope
           end)
  end
end
