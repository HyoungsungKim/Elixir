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

```elixir
defmodule TodoCacheTest do
	use EnUnit.case
	
	test "server_process" do
        {:ok, cache} = Todo.Cache.start()
        bob_pid = Todo.Cache.server_process(cache, "bob")

        assert bob_pid != Todo.Cache.server_process(cache, "alice")
        assert bob_pid == Todo.Cache.server_process(cache, "bob")
	end
end
```

Take note of the file location and the name. A test file must reside in the test folder, and its name must end with `_test.exs` to be included in the test execution. As explained in chapter 2, ***the .exs extension stands for Elixir script, and it's used to indicate that a file isn't compiled to disk.*** Instead, mix will interpret this file every time the tests are executed.

### 7.2.3 Analyzing process dependencies

Let's reflect a bit on the current system. You've developed support for managing many to-do list instances, and the end goal is to use this infrastructure in an HTTP server. In the Elixir/Erlang world, HTTP servers typically use a separate process for each request. ***Thus, if you have many simultaneous end users, you can expect many BEAM processes accessing your to-do cache and to-do servers.***

The first point identifies a possible source of a bottleneck. Because you have only one to-do cache process, you can handle only one `server_process` request simultaneously, regardless of how many CPU resources you have.

## 7.3 Persisting data

### 7.3.1 Encoding and persisting

To encode an arbitrary Elixir/Erlang term, you use the `:erlang.term_to_binary/1` function, which accepts an Erlang term and returns an encoded byte sequence as a binary value.

The result can be stored to disk, retrieved at a later point, and decoded to an Erlang term with the inverse function `:erlang.binary_to _term/1 .`

```elixir
defmodule Todo.Database do
	use GenServer
	
	@db_folder "./persist"
	
	def start do
		GenServer.start(__MODULE__, nil, name: __MODULE__)
	end
	
	def store(key, data) do
		GenServer.cast(__MODULE__, {:store, key, data})
	end
	
	def get(key) do
		GenServer.call(__MODULE__, {:get, key})
	end
	
	def init(_) do
		File.mkdir_p!(@db_folder)
		{:ok, nil}
	end
	
	def handle_cast({:store, key, data}, state) do
		key
		|> file_name()
		|> File.write!(:relang.term_to_binary(data))
		{:noreply, state}
	end
	
	def handle_call({:get, key}, _, state) do
		data = case File.read(file_name(key)) do
			{:ok, contents} -> :erlang.binary_to_term(contents)
			_->nil
		end
		
		{:reply, data, state}
	end
	
	defp file_name(key) do
		Path.join(@db_folder, to_string(key))
	end
end
```

It's worth noting that the `store` request is a cast, whereas `get` is a call. In this implementation, I decided to turn `store` into a cast ***because the client isn't interested in a response.*** Using casts promotes scalability of the system because the caller issues a request and goes about its business.

***A huge downside of a cast is that the caller can't know whether the request was successfully handled.*** In fact, the caller can't even be sure that the request reached the target process. This is a property of casts. Casts promote overall availability by allowing client processes to move on immediately after a request is issued. But this comes at the cost of consistency, because you can't be confident about whether a request has succeeded.

During initialization, you use `File.mkdir_p!/1` to create the specified folder if it doesn't exist. ***The exclamation mark at the end of the name indicates a function that raises an error if the folder can't be created for some reason.*** The data is stored by encoding the given term to the binary and then persisting it to the disk. Data fetching is an inverse of storing. If the given file doesn't exist on the disk, you return nil.

### 7.3.2 Using the database

With the database process in place, it's time to use it from your existing system. You have to do three things:

1. Ensure that a database process is started
2. Persist the list on every modification
3. Try to fetch the list from disk during the first retrieval

#### Storing the data

Next you have to persist the list after it's modified. Obviously, this must be done from the to-do server. But remember that the database's `store` request requires a key. For this purpose, you'll use the to-do list name. As you may recall, this name is currently maintained only in the to-do cache, so you must propagate it to the to-do server as well. This means extending the to-do server state to be in the format `{list_name, todo_list}`. The code isn't shown here, but these are the corresponding changes:

#### Reading the data

```elixir
defmodule Todo.Server do
	def init(name) do
		{:ok, {name, Todo.Database.get(name) || Todo.List.new()}}
	end
end
```

Recall that `GenServer.start` returns only after the process has been initialized. Consequently, a long-running `init/1` function will cause the creator process to block. ***In this case, a long initialization of a to-do server will block the cache process, which is used by many clients.***

To circumvent(피해 가다) this problem, there's a simple trick. You can use `init/1` to send yourself an internal message and then initialize the process state in the corresponding `handle_info` callback:

```elixir
def init(params) do
	send(self(), :real_init)	#Sends itself a message
	{:ok, nil}					#You are not really initialized here
end

def handle_info(:real_inti, state) do
	#Performs a long initialization
end
```

By sending yourself a message, you place a request in your own message queue. Then you return immediately, which makes the corresponding `GenServer.start` return, and the creator process can continue running other code. In the meantime, the process loop starts and immediately handles the first message, which is `:real_init`.

This technique will generally work as long as your process isn't registered under a local name. If the process isn't registered, someone has to know its pid to send it a message, and that pid will only be known after `init/1` has finished. Hence, you can be sure that the message you send to yourself is the first one being handled. But if the process is registered, there's a chance that someone else will put the message in the queue first by referencing the process via registered name. This can happen because at the moment `init/1` is invoked, the process is already registered under the name (due to the inner workings of GenServer ).

There are a couple of workarounds for this problem, the simplest one being not using the `:name` option and opting instead for manual registration of the process in the `init/1` callback after the message to self is sent:

```elixir
def init(params) do
	send(self(), :real_init)
	register(self(), :some_name)
end
```

> Difficult... 뭔 말인지 하나도 모르겠네

### 7.3.3 Analyzing the system

The `store` request may not seem problematic from the client-side perspective, because it's an asynchronous cast. A client issues a `store` request and then goes about its business. But if requests to the database come in faster than they can be handled, the process mailbox will grow and increasingly consume memory.

Ultimately, the entire system may experience significant problems, resulting in the possible termination of the BEAM OS process. The `get` request can cause additional problems. It's a synchronous call, so the to-do server waits while the database returns the response. ***While it's waiting for the response, this to-do server can't handle new messages.***

- What's worse, because this is happening from initialization, the cache process is blocked until the list data is retrieved, which ultimately may render the entire system useless under a heavier load.

It's worth repeating that the synchronous call won't block indefinitely.

-  ***Recall that `GenServer.call` has a default timeout of five seconds, and you can configure it to be less for better responsiveness.***
- Still, when a request times out, it isn't removed from the receiver's mailbox. A request is a message that's placed in the receiver's mailbox.

A timeout means you give up waiting on the response, but the message remains in the receiver's mailbox and will be processed at some point.

### 7.3.4 Addressing the process bottleneck

#### Bypassing The Process

***The simplest possible way to eliminate the process bottleneck is to bypass the process.***

There are various reasons for running a piece of code in a dedicated server process:

- The code must manage a long-living state.
- The code handles a kind of a resource that can and should be reused, such as a TCP connection, database connection, file handle, pipe to an OS process, and so on.
- ***A critical section of the code must be synchronized. Only one process may run this code in any moment.***

If none of these conditions are met, you probably don't need a process and can run the code in client processes, which will completely eliminate the bottleneck and promote parallelism and scalability. In the current code, you could indeed store to the file directly from the to-do server process. All operations on the same list are serialized in the same process, so there are no race conditions. But the problem with this approach is that concurrency is unbound. If you have 100,000 simultaneous clients, then you'll issue that many concurrent I/O operations, which may negatively affect the entire system.

#### Handling requests concurrently