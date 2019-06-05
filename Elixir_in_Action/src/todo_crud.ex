defmodule TodoList do
  defstruct auto_id: 1, entries: %{}
  def new(), do: %TodoList{}  #Create a new instance

  def add_entry(todo_list, entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)
    new_entries = Map.put(
      todo_list.entries,
      todo_list.auto_id,
      entry
    )

    %TodoList{todo_list |
      entries: new_entries,
      auto_id: todo_list.auto_id + 1
    }
  end

  def entries(todo_list, date) do
    todo_list.entries
    |> Stream.filter(fn {_, entry}) -> entry.date == date end)
    |> Enum.map(fn {_, entry} -> entry) end
  end

  def update_entry(todo_list, enrty_id, updater_fun) do
    #iex> TodoList.update_entry(todo_list, 1, &Map.put(&1, :date, ~D[2018-12-20]))
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      #old_entry is value not key
      {:ok, old_entry} ->
        new_entry = updater_fun.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entries.id, new_entry)
        %ToDoList{todo_list | entries: new_entries}
    end
  end

end
