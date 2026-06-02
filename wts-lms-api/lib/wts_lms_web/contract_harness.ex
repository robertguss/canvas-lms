defmodule WtsLmsWeb.ContractHarness do
  @moduledoc """
  Minimal JSON response-shape contract harness for scaffold gates.

  The harness validates decoded JSON maps against simple schema descriptors so
  future Phoenix controller tests can reject accidental API shape drift before
  domain features are implemented.
  """

  def validate_json_shape(json, schema) when is_map(schema) do
    case validate_value(json, schema, []) do
      [] -> :ok
      errors -> {:error, Enum.reverse(errors)}
    end
  end

  def validate_json_shape(_json, _schema), do: {:error, ["schema must be a map"]}

  defp validate_value(value, schema, path) when is_map(schema) and is_map(value) do
    Enum.reduce(schema, [], fn {key, expected}, errors ->
      if Map.has_key?(value, key) do
        validate_value(Map.fetch!(value, key), expected, path ++ [key]) ++ errors
      else
        ["#{format_path(path ++ [key])} is required" | errors]
      end
    end)
  end

  defp validate_value(value, schema, path) when is_map(schema) do
    ["#{format_path(path)} expected map, got #{type_name(value)}"]
  end

  defp validate_value(value, {:list, item_schema}, path) when is_list(value) do
    value
    |> Enum.with_index()
    |> Enum.flat_map(fn {item, index} -> validate_value(item, item_schema, path ++ [index]) end)
  end

  defp validate_value(value, {:list, _item_schema}, path) do
    ["#{format_path(path)} expected list, got #{type_name(value)}"]
  end

  defp validate_value(value, :string, _path) when is_binary(value), do: []
  defp validate_value(value, :integer, _path) when is_integer(value), do: []
  defp validate_value(value, :boolean, _path) when is_boolean(value), do: []
  defp validate_value(value, :map, _path) when is_map(value), do: []

  defp validate_value(value, expected, path)
       when expected in [:string, :integer, :boolean, :map] do
    ["#{format_path(path)} expected #{expected}, got #{type_name(value)}"]
  end

  defp validate_value(_value, expected, path) do
    ["#{format_path(path)} has unsupported schema #{inspect(expected)}"]
  end

  defp format_path([]), do: "response"
  defp format_path([first | rest]), do: Enum.reduce(rest, to_string(first), &append_path/2)

  defp append_path(index, path) when is_integer(index), do: "#{path}[#{index}]"
  defp append_path(segment, path), do: "#{path}.#{segment}"

  defp type_name(value) when is_binary(value), do: "string"
  defp type_name(value) when is_integer(value), do: "integer"
  defp type_name(value) when is_boolean(value), do: "boolean"
  defp type_name(value) when is_list(value), do: "list"
  defp type_name(value) when is_map(value), do: "map"
  defp type_name(nil), do: "null"
  defp type_name(_value), do: "unknown"
end
