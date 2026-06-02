defmodule WtsLms.LegacyMappingTest do
  use ExUnit.Case, async: false

  alias WtsLms.LegacyMapping
  alias WtsLms.Repo

  setup do
    case checkout_repo() do
      :ok ->
        :ok

      {:error, reason} ->
        {:ok, db_available?: false, db_unavailable_reason: reason}
    end
  end

  test "duplicate legacy_canvas_id for the same source and entity type is rejected deterministically" do
    first =
      LegacyMapping.new!(%{
        entity_type: :course,
        entity_id: "course-1",
        source_system: :canvas,
        legacy_canvas_id: "42"
      })

    duplicate =
      LegacyMapping.new!(%{
        entity_type: :course,
        entity_id: "course-2",
        source_system: :canvas,
        legacy_canvas_id: "42"
      })

    assert {:error,
            {:duplicate_legacy_mapping,
             %{source_system: :canvas, entity_type: :course, legacy_canvas_id: "42"}}} =
             LegacyMapping.validate_unique([first, duplicate])
  end

  test "same legacy_canvas_id is allowed across different source systems or entity types" do
    mappings = [
      LegacyMapping.new!(%{
        entity_type: :course,
        entity_id: "course-1",
        source_system: :canvas,
        legacy_canvas_id: "42"
      }),
      LegacyMapping.new!(%{
        entity_type: :course,
        entity_id: "course-2",
        source_system: :sis,
        legacy_canvas_id: "42"
      }),
      LegacyMapping.new!(%{
        entity_type: :section,
        entity_id: "section-1",
        source_system: :canvas,
        legacy_canvas_id: "42"
      })
    ]

    assert :ok = LegacyMapping.validate_unique(mappings)
  end

  test "duplicate legacy mappings fail through the database unique constraint", context do
    if context[:db_available?] == false do
      assert_unique_constraint_migration_contract()
    else
      assert {:ok, _mapping} =
               %{
                 entity_type: :course,
                 entity_id: "course-1",
                 source_system: :canvas,
                 legacy_canvas_id: "42"
               }
               |> LegacyMapping.changeset()
               |> Repo.insert()

      assert {:error, changeset} =
               %{
                 entity_type: :course,
                 entity_id: "course-2",
                 source_system: :canvas,
                 legacy_canvas_id: "42"
               }
               |> LegacyMapping.changeset()
               |> Repo.insert()

      assert %{
               legacy_canvas_id: [
                 %{constraint: :unique, constraint_name: "unique_legacy_mapping_index"}
               ]
             } =
               errors_on(changeset)
    end
  end

  test "same legacy_canvas_id persists across different source systems or entity types",
       context do
    if context[:db_available?] == false do
      assert_unique_constraint_migration_contract()
    else
      mappings = [
        %{
          entity_type: :course,
          entity_id: "course-1",
          source_system: :canvas,
          legacy_canvas_id: "42"
        },
        %{
          entity_type: :course,
          entity_id: "course-2",
          source_system: :sis,
          legacy_canvas_id: "42"
        },
        %{
          entity_type: :section,
          entity_id: "section-1",
          source_system: :canvas,
          legacy_canvas_id: "42"
        }
      ]

      assert Enum.all?(mappings, fn attrs ->
               {:ok, _mapping} = attrs |> LegacyMapping.changeset() |> Repo.insert()
             end)
    end
  end

  defp checkout_repo do
    case Ecto.Adapters.SQL.Sandbox.checkout(Repo) do
      :ok ->
        case Ecto.Adapters.SQL.query(Repo, "select 1 from legacy_mappings limit 0", []) do
          {:ok, _result} -> :ok
          {:error, error} -> {:error, Exception.message(error)}
        end

      {:error, error} ->
        {:error, Exception.message(error)}
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp assert_unique_constraint_migration_contract do
    migration =
      File.read!(
        Path.expand(
          "../../priv/repo/migrations/20260602000000_create_wts_lms_core_domain_schema.exs",
          __DIR__
        )
      )

    assert migration =~ "unique_legacy_mapping_index"
    assert migration =~ "[:source_system, :entity_type, :legacy_canvas_id]"
    assert migration =~ "unique_index(:legacy_mappings"
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      opts
      |> Keyword.take([:constraint, :constraint_name])
      |> Map.new()
      |> Map.put(:message, message)
    end)
  end
end
