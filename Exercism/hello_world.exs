defmodule HelloWorld do
  @doc """
  Simply returns "Hello, World!"
  """
  @spec hello :: String.t()
  def hello do
    "Your implementation goes here"
    IO.puts("Hello, World")
  end
end
