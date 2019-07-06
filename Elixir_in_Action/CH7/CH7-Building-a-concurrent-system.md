# CH6 Building a concurrent system

Your ultimate goal is to build a distributed HTTP server that can handle many end users who are simultaneously manipulating many to-do lists. In this chapter, you'll develop an infrastructure for handling multiple to-do lists and persisting them to disk. But first, let's look at how you can manage more complex projects with the mix tool.

## 7.1 Working with the mix project

```elixir
mix new todo
```

The result is a folder that contains only a handful of files, including a readme, unit-test support files, and the .gitignore file. mix projects are extremely simple and don't introduce a plethora of auto-generated files.

You can also use a special way of starting `iex`, which is useful when you want to play with mix projects in the Elixir shell. When you run `iex -S mix` , two things happen.

- First, the project is compiled (just as with mix compile ). If this is successful, the shell is started, and all modules from the project are available. The word available here means that all generated BEAM files (binaries that represent compiled modules) are in load paths.

There are no hard rules regarding how files should be named and organized, but there are some preferred conventions:

- You should place your modules under a common top-level alias. For example, modules might be called `Todo.List`, `Todo.Server`, and so on. ***This reduces the chance of module names conflicting*** when you combine multiple projects into a single system.
- In general, ***one file should contain one module.*** Occasionally, if a helper module is small and used only internally, it can be placed in the same file as the module using it. If you want to implement protocols for the module, you can do this in the same file as well.
- ***A filename should be an underscore case*** (aka snake case) version of the main module name it implements. For example, a `TodoServer` module would reside in a `todo_server.ex` file in the lib folder.
- The folder structure should correspond to multi-part module names. A module called `Todo.Server` should reside in the file lib/todo/server.ex.

## 7.2 Managing multiple to-do lists

There are two approaches to extending this code to work with multiple lists:

- Implement a `TodoListCollection` pure functional abstraction to work with multiple to-do lists. Modify `Todo.Server` to use the new abstraction as its internal state.
- Run one instance of the existing to-do server for each to-do list.

The problem with the first approach is that you'll end up having only one process to serve all users. This approach isn't very scalable. If the system is used by many different users, they'll frequently block each other, competing for the same resource — a single server process that performs all tasks.
***The alternative is to use as many processes as there are to-do lists. With this approach, each list is managed concurrently, and the system should be more responsive and scalable.***

To run multiple to-do server processes, you need another entity — something you'll use to create `Todo.Server` instances or fetch the existing ones. ***That “something” must manage a state — essentially a key/value structure that maps to-do list names to to-do server pids.*** This state will of course be mutable (the number of lists changes over time) and must be available during the server's lifetime.

Therefore, you'll introduce another process: a to-do cache. You'll run only one instance of this process, and it will be used to create and return a pid of a to-do server process that corresponds to the given name. The module will export only two functions: `start/0`, which starts the process, and `server_process/2`, which retrieves a to-do server process (its pid) for a given name, optionally starting the process if it isn't already running.

### 7.2.1 Implementing a cache

```elixir
defmodule Todo.Cache do
	use GenServer
	
	def init(_) dp
		{:ok, %{}}
	end
end
```

### 7.2.2 Writing tests

***Now that the code is organized in the mix project, you can write automated tests.*** The testing framework for Elixir is called ex_unit , and it's included in the Elixir distribution. Running tests is as easy as invoking mix test . All you need to do is write the test code.