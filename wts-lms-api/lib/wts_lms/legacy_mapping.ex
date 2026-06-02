defmodule WtsLms.LegacyMapping do
  @moduledoc """
  Legacy Canvas mapping contract shared by imports and schema tests.

  The deterministic uniqueness check mirrors the migration-level unique index on
  `source_system`, `entity_type`, and `legacy_canvas_id` so duplicate Canvas IDs
  cannot map to two WTS records for the same source/type pair.
  """

  defstruct [
    :id,
    :entity_type,
    :entity_id,
    :source_system,
    :legacy_canvas_id,
    :import_batch_id,
    :last_imported_at,
    :source_updated_at,
    :inserted_at,
    :updated_at
  ]

  def fields do
    [
      :id,
      :entity_type,
      :entity_id,
      :source_system,
      :legacy_canvas_id,
      :import_batch_id,
      :last_imported_at,
      :source_updated_at,
      :inserted_at,
      :updated_at
    ]
  end

  def new!(attrs) when is_map(attrs) do
    attrs = Map.new(attrs)
    now = Map.get(attrs, :inserted_at) || DateTime.utc_now() |> DateTime.truncate(:second)

    attrs =
      attrs
      |> Map.put_new(:id, "legacy_mapping-" <> to_string(Map.fetch!(attrs, :entity_type)) <> "-" <> to_string(Map.fetch!(attrs, :legacy_canvas_id)))
      |> Map.put_new(:source_system, :canvas)
      |> Map.put_new(:inserted_at, now)
      |> Map.put_new(:updated_at, now)

    struct!(__MODULE__, attrs)
  end

  def validate_unique(mappings) when is_list(mappings) do
    mappings
    |> Enum.reduce_while(MapSet.new(), fn mapping, seen ->
      key = {mapping.source_system, mapping.entity_type, mapping.legacy_canvas_id}

      if MapSet.member?(seen, key) do
        {:halt,
         {:error,
          {:duplicate_legacy_mapping,
           %{
             source_system: mapping.source_system,
             entity_type: mapping.entity_type,
             legacy_canvas_id: mapping.legacy_canvas_id
           }}}}
      else
        {:cont, MapSet.put(seen, key)}
      end
    end)
    |> case do
      %MapSet{} -> :ok
      error -> error
    end
  end
end
