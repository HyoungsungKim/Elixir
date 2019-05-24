defmodule RNATranscription do
  @doc """
  Transcribes a character list representing DNA nucleotides to RNA

  ## Examples

  iex> RNATranscription.to_rna('ACTG')
  'UGAC'
  """

  @spec to_rna([char]) :: [char]
def to_rna(dna) do
    to_rna_tailRecursion(dna, [])
end

defp to_rna_tailRecursion([head | tail], result) do
  #IO.puts(tail)
  cond do
    head == ?G ->
      head = ?C
    head ==?C ->
      head = ?G
    head == ?T ->
      head = ?A
    head == ?A ->
      head = ?U
  end
  to_rna_tailRecursion(tail, [head | result])
end

defp to_rna_tailRecursion([], result) do
  Enum.reverse(result)
end

end
