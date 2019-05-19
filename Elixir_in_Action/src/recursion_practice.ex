defmodule Recursion_prac do
  def list_len([]) do
    0
  end

  def list_len([_ | tail]) do
    1 + list_len(tail)
  end

  def range(from, to) when from > to do
    []
  end

  def range(from, to) do
    [from | range(from + 1, to)]
  end

  def postive([]) do
    0
  end

  def postive([head | tail]) when head >= 0 do
    [head | postive(tail)]
  end

  def postive([_ | tail]) do
    postive(tail)
  end
end
