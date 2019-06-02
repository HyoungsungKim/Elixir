defmodule MultiDict do
  def new(), do: %{}

  def add(dict, key, value) do
    # & : capture function -> It is used like function pointer in C/C++
    # &1 is value placeholder
    Map.update(dict, key, [value], &[value | &1])
  end

  def get(dict, key) do
    Map,get(dict, key, [])
  end
end
