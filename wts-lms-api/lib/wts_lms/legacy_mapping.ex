defmodule WtsLms.LegacyMapping do
  @moduledoc """
  Legacy Canvas mapping contract shared by imports and schema tests.

  The changeset uses the migration-level unique index on `source_system`,
  `entity_type`, and `legacy_canvas_id` so duplicate Canvas IDs cannot map to
  two WTS records for the same source/type pair.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @timestamps_opts [type: :utc_datetime]

  @fields [
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

  @entity_types [
    :account,
    :academic_term,
    :user,
    :role,
    :course,
    :section,
    :enrollment,
    :learning_module,
    :page,
    :content_file,
    :assignment_group,
    :assignment,
    :submission,
    :grade_item,
    :grade,
    :notification
  ]

  schema "legacy_mappings" do
    field(:entity_type, Ecto.Enum, values: @entity_types)
    field(:entity_id, :string)
    field(:source_system, Ecto.Enum, values: [:canvas, :sis])
    field(:legacy_canvas_id, :string)
    field(:import_batch_id, :string)
    field(:last_imported_at, :utc_datetime)
    field(:source_updated_at, :utc_datetime)

    timestamps()
  end

  def fields do
    @fields
  end

  def changeset(attrs) when is_map(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(mapping, attrs) when is_map(attrs) do
    attrs = Map.new(attrs)

    mapping
    |> cast(attrs, [
      :id,
      :entity_type,
      :entity_id,
      :source_system,
      :legacy_canvas_id,
      :import_batch_id,
      :last_imported_at,
      :source_updated_at
    ])
    |> put_change(:id, Map.get(attrs, :id) || Map.get(attrs, "id") || generated_id(attrs))
    |> validate_required([:id, :entity_type, :entity_id, :source_system, :legacy_canvas_id])
    |> unique_constraint(:legacy_canvas_id, name: :unique_legacy_mapping_index)
  end

  def new!(attrs) when is_map(attrs) do
    attrs = Map.new(attrs)
    now = Map.get(attrs, :inserted_at) || DateTime.utc_now() |> DateTime.truncate(:second)

    attrs =
      attrs
      |> Map.put_new(:id, generated_id(attrs))
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

  defp generated_id(attrs) do
    "legacy_mapping-" <>
      to_string(Map.fetch!(attrs, :entity_type)) <>
      "-" <>
      to_string(Map.fetch!(attrs, :entity_id)) <>
      "-" <> to_string(Map.fetch!(attrs, :legacy_canvas_id))
  end
end
