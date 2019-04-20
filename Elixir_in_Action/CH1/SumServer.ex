defmodule SumServer do
  use EXActor.GenServer

  defstart start

  defcall sum(a,b) do
    reply(a + b)
  end
end
