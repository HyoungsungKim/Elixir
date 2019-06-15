defmodule DataBaseServer do
  def start do
    spawn(fn ->
      connection = :rand.uniform(1000)
      #Rand is from erlang
      loop(connection)
    end)
  end

  defp loop(connection) do
    receive do
      {:run_query, from_pid, query_def} ->
        query_result = run_query(connection, query_def)
        send(from_pid, {:query_result, query_result})
      end
      loop(connection)
    end

    defp run_query(connection, query_def) do
      Process.sleep(2000)
      "connection #{connection}: #{query_def} result"
    end

  def run_async(server_pid, query_def) do
    send(server_pid, {:run_query, self(), query_def})
  end

  def get_result do
    receive do
      {:query_result, result} -> result
    after
      5000 -> {:error, :timeout}
    end
  end

end
