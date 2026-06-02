defmodule WtsLms.LegacyMappingTest do
  use ExUnit.Case, async: true

  alias WtsLms.LegacyMapping

  test "duplicate legacy_canvas_id for the same source and entity type is rejected deterministically" do
    first = LegacyMapping.new!(%{entity_type: :course, entity_id: "course-1", source_system: :canvas, legacy_canvas_id: "42"})
    duplicate = LegacyMapping.new!(%{entity_type: :course, entity_id: "course-2", source_system: :canvas, legacy_canvas_id: "42"})

    assert {:error, {:duplicate_legacy_mapping, %{source_system: :canvas, entity_type: :course, legacy_canvas_id: "42"}}} =
             LegacyMapping.validate_unique([first, duplicate])
  end

  test "same legacy_canvas_id is allowed across different source systems or entity types" do
    mappings = [
      LegacyMapping.new!(%{entity_type: :course, entity_id: "course-1", source_system: :canvas, legacy_canvas_id: "42"}),
      LegacyMapping.new!(%{entity_type: :course, entity_id: "course-2", source_system: :sis, legacy_canvas_id: "42"}),
      LegacyMapping.new!(%{entity_type: :section, entity_id: "section-1", source_system: :canvas, legacy_canvas_id: "42"})
    ]

    assert :ok = LegacyMapping.validate_unique(mappings)
  end
end
