defmodule Recursion_prac_tc do
  def list_len([_ | tail]) do
    list_len_tc(1, tail)
  end

  def list_len_tc(currentLength, []) do
    currentLength
  end

  def list_len_tc(currentLength, [_ | tail]) do
    currentLength = currentLength + 1
    list_len_tc(currentLength, tail)
  end

  def range(from, to) do
    range_tc(from, to, [])
  end

  def range_tc(from, to, result) when from > to do
    result
  end

  # 와... 기가 막히네;;;
  def range_tc(from, to, result) do
    range_tc(from, to - 1, [to | result])
  end

  def postive([head | tail]) do
    postive_tc([head | tail], [])
  end

  defp postive_tc([head | tail], result) when head >= 0 do
    postive_tc(tail, [head | result])
  end

  defp postive_tc([head | tail], result) when head < 0 do
    postive_tc(tail, result)
  end

  defp postive_tc([], result) do
    Enum.reverse(result)
  end
end
