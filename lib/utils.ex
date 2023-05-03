defmodule Utils do
  def to_atoms(map) when is_map(map) do
    map
    |> Enum.map(fn
      {k, v} when is_list(k) ->
        {String.to_existing_atom(k), to_atoms(v)}

      {k, v} when is_binary(k) ->
        {String.to_existing_atom(k), to_atoms(v)}

      {k, v} ->
        {k, to_atoms(v)}
    end)
    |> Map.new()
  end

  def to_atoms(value) when is_list(value) do
    Enum.map(value, &to_atoms/1)
  end

  def to_atoms(value) do
    value
  end
end
