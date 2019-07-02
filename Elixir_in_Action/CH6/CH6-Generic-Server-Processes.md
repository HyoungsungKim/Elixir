# CH6 Generic Server Processes

## 6.1 Building a generic server process

All code that implements a server process needs to do the following:

- Spawn a separate process
- Run an infinite loop in the process
- Maintain the process state
- React to messages
- Send a response back to the caller

No matter what kind of server process you run, you'll always need to do these tasks.

### 6.1.1 Plugging in with modules

The generic code drives the entire process, and the specific implementation must fill in the missing pieces. Therefore, you need a plug-in mechanism that lets the generic code call into the concrete implementation when a specific decision needs to be made. The simplest way to do this si to use modules. ***Remember that a module name is an atom.***

```elixir
iex>some_module = IO
iex>some_module.puts("Hello")
Hello
```

You can use this feature to provide callback hooks from the generic code. In particular, you can take the following approach:

1. Make the generic code accept a plug-in module as the argument. That module is called a `callback module`
2. Maintain the module atom as part of the process state.
3. Invoke callback-module functions when needed.

Obviously, for this to work, a callback module must implement and export a well-defined set of functions.

### 6.1.2 Implementing the generic code

First you need to start the process and initialize its state, as shown in the following listing.

```elixir
defmodule ServerProcess do
	def start(callback_module) do
		spawn(fn ->
			initial_state = callback_module.init()
			loop(callback_module, initial_state)
		end)
	end
end
```

The server process must receive a message, handle it, send the response message back to the caller, and change the process state. The generic code is responsible for receiving and sending messages, whereas the specific implementation must handle the message and return the response and the new state. The idea is illustrated in the following listing.

```elixir
defp loop(callback_module, current_state) do
	receive do
		{request, caller} ->
			{response, new_state} = callback_module.handle_call(request, current_state)
			send(caller, {:response, response})
			loop(callback_module, new_state)
	end
end	
```

Here, you expect a message in the form of a {request, caller} tuple. The request is data that identifies the request and is meaningful to the specific implementation. The callback function `handle_call/2` takes the request payload and the current state, and it must return a {response, new_state} tuple.

```elixir
def call(server_pid, request) do
	send(server_pid, {request, self()})
	receive do
		{:response, response} ->
			response
		end
	end
end
```

### 6.1.3 Using the generic abstraction

To test the server process, you'll implement a simple key/value store. It will be a process that can be used to store mappings between arbitrary terms.

***Remember that the callback module must implement two functions: `init/0` , which creates the initial state, and `handle_call/2` , which handles specific requests. The code is shown next.*** 

```elixir
defmodule KeyValueStore do
	def init do
		%{}
	end
	
	def handle_call({:put, key, value}, state) do
		{:ok, Map.put(state, key, value)}
	end
	
	def handle_call({:get, key}, state) do
		{Map.get(state, key), state}
	end
end
```

## 6.2 Using GenServer

Some of the compelling features provided by GenServer include the following:

- Support for calls and casts
- Customizable timeouts for call requests
- Propagation of server-process crashes to client processes waiting for a response
- Supporting for distributed systems

### 6.2.1 OTP behaviours

In Erlang terminology, a behaviour is generic code that implements a common pattern. The generic logic is exposed through the behaviour module, and you can plug into it by implementing a corresponding callback module. The callback module must satisfy a contract defined by the behaviour, meaning it must implement and export a set of functions. The behaviour module then calls into these functions, allowing you to provide your own specialization of the generic code.

The Erlang standard library includes the following OTP behaviours:

- gen_server : Generic implementation of a stateful server process
- supervisor : Provides error handling and recovery in concurrent systems
- application : Generic implementation of components and libraries
- gen_event : Provides event-handling support
- gen_statem : Runs a finite state machine in a stateful server process

Elixir provides its own wrappers for the most frequently used behaviours via the modules `GenServer`, `Supervisor`, and `Application`.

### 6.2.2 Plugging into GenServer

```elixir
defmodule KeyValueStore do
	use GenServer
end
```

The `use` macro is a language feature you haven't seen previously. During compilation, when this instruction is encountered, ***the specific macro from the GenServer module is invoked.*** That macro then injects a bunch of functions into the calling module (KeyValueStore, in this case). 

Using `GenServer` is roughly similar to using ServerProcess. There are some differences in the format of the returned values, but the basic idea is the same.

Many functions are automatically included in the module due to use GenServer. These are all callback functions that need to be implemented for you to plug into the GenServer behaviour.

you can plug your callback module into the behaviour. To start the process, use the `GenServer.start/2` function

### 6.2.3 Handling requests

Now you can convert the KeyValueStore to work with GenServer. To do this, you need to implement three callbacks: `init/1`, `handle_cast/2`, and `handle_call/3`,

- init/1 accepts one argument. This is the second argument provided to GenServer.start/2, and you can use it to pass data to the server process while starting it.
- The result of init/1 must be in the format {:ok, initial_state}.
- handle_cast/2 accepts the request and the state and should return the result in the format {***:noreply***, new_state}.
- handle_call/3 takes the request, the caller information, and the state. It should return the result in the format {***:reply***, response, new_state}.

```elixir
defmodule KeyValueStore do
	use GenServer
	
	def init(_) do
		{:ok, %{}}
	end
	
	def handle_cast({:put, key, value}, state) do
		{:noreply, Map.put(state, key, value)}
	end
	
	def handle_call({:get, key}, _, state) do
		{:reply, Map.get(state, key), state}
	end
end
```

The second argument to handle_call/3 is a tuple that contains the request ID (used internally by the GenServer behaviour) and the pid of the caller. This information is in most cases not needed, so in this example you ignore it.

The only things missing are interface functions. ***To interact with a GenServer process, you can use functions from the GenServer module.*** In particular, you can use GenServer.start/2 to start the process and GenServer.cast/2 and GenServer.call/2 to issue requests.

```elixir
#Adding interface functions
defmodule KeyValueStore do
	use GenServer
	
	def start do
		GenServer.start(KeyValueStore, nil)
	end
	
	def put(pid, key, value) do
		GenServer.cast(pid, {:put, key, value})
	end
	
	def get(pid, key) do
		GenServer.call(pid, {:get, key})
	end
end
```

There are many differences between ServerProcess and GenServer, but a couple points deserve special mention.

- First, `GenServer.start/2` works ***synchronously.*** In other words, `start/2` returns only after the `init/1` callback has finished in the server process. Consequently, the client process that starts the server is blocked until the server process is initialized.
- Second, note that `GenServer.call/2` doesn't wait indefinitely(무기한으로) for a response. By default, if the response message doesn't arrive ***in five seconds,*** an error is raised in the client process. You can alter this by using `GenServer.call(pid, request, timeout)`, where the timeout is given in milliseconds.
- In addition, if the receiver process happens to terminate while you're waiting for the response, ***GenServer detects it and raises a corresponding error in the caller process.***

### 6.2.4 Handling plain messages

