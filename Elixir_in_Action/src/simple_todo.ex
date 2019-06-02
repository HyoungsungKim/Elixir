defmodule SimpleTodoList do
  def new(), do: %{}

  def add_entry(todo_list, date, title) do
    Map.update(
      todo_list,
      date,
      #lambda : if no value exists for the given key, the initial value is used. Otherwise, the updater lambda is called.
      [title], fn titles -> [title | titles] end
    )
end

  def entries(todo_list, date) do
    Map.get(todo_list, date, [])
end
end
