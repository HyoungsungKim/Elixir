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

In ServerProcess, notice that you don't send the plain request payload to the server process; you include
additional data, such as the request type and the caller for call requests.

`GenServer` uses a similar approach, using :`$gen_cast` and :`$gen_call` atoms to decorate cast and call messages. You don't need to worry about the exact format of those messages, but it's important to understand that GenServer internally uses particular message formats and handles those messages in a specific way. ***It's important to understand that GenServer internally uses particular message formats and handles those messages in a specific way.***

Occasionally you may need to handle messages that aren't specific to GenServer . For example, imagine that you need to do a periodic cleanup of the server process state. You can use the Erlang function `:timer.send_interval/2`, which periodically sends a message to the caller process. Because this message isn't a GenServer-specific message, it's not treated as a `cast` or a `call`. Instead, for such plain messages, GenServer calls the `handle_info/2` callback, giving you a chance to do something with the message.

```elixir
iex(1)> defmodule KeyValueStore do
	use GenServer
	def init(_) do
		:timer.send_interval(5000, :cleanup)
		{:ok, %{}}
	end
	
	def handle_info(:cleanup, state) do
		IO.puts "Performing cleanup.."
		{:noreply, state}
	end
end
```

### 6.2.5 Other GenServer feature

#### Compile-time checking

One problem with the callbacks mechanism is that it's easy to make a subtle mistake when defining a callback function.

```elixir
defmodule EchoServer do
	@impl GenServer
	def handle_call(some_request, server_state) do
		{:reply, some_request, server_state}
	end
end
```

Issuing a call caused the server to crash with an error that no `handle_call/3` clause is provided, although the clause is listed in the module. What happened? If you look closely at the definition of EchoServer, you'll see that you defined `handle_call/2`, while GenServer requires `handle_call/3 `.

> 호출 할 때 모듈끼리 같은 이름의 함수가 존재 하면 @으로 어떤 모듈의 함수 구현인지 특정해줌

You can get a compile-time warning here if you tell the compiler that the function being defined is supposed to satisfy a contract by some behaviour. To do this, you need to provide the `@impl` module attribute immediately before the first clause of the call-back function:

***It's a good practice to always specify the @impl attribute for every callback function you define in your modules.***

#### Name Registration

Recall from chapter 5 that a process can be registered under a local name (an atom), where local means the name is registered only in the currently running BEAM instance. ***This allows you to create a singleton process that you can access by name without needing to know its pid.***

Local registration is an important feature because it supports patterns of fault-tolerance and distributed systems. You'll see exactly how this works in later chapters, but it's worth mentioning that you can provide the process name as an option to `GenServer.start`:

```elixir
GenServer.start(CallbackModule, init_parm, name: :some_name)
#name: :some_name -> register the process under a name
GenServer.call(:some_name, ...)
GenServer.cast(:some_name, ...)
```

***The most frequent approach is to use the same name as the module name.***

> 지금까지는 GenServer.start() -> 매개변수 없이 사용 했음

```elixir
defmodule KeyValueStore do
	use GenServer
	def start() do
		GenServer.start(KeyValueStore, nil, name: KeyValueStore)
	end
	
	def put() do
		GenserVer.cast(__MODULE__, {:put, key, value})
	end
end
```

#### Stopping The Server

- `{:ok, initial_state}` from `init/1`
- `{:reply, response, new_state}` from `handle_call/3`
- `{:noreply, new_state}` from `handle_cast/2` and `handle_info/2`

There are additional possibilities, the most important one being the option to stop the server process.

In `init/1`, you can decide against starting the server. In this case, you can either return `{:stop, reason}` or `:ignore`. ***In both cases, the server won't proceed with the loop, and will instead terminate.***

If `init/1` returns `{:stop, reason}`, the result of `start/2` will be `{:error, reason}`  In contrast, if `init/1` returns `:ignore`, the result of `start/2` will also be `:ignore`. The difference between these two return values is in their intention.

- You should opt for `{:stop, reason}` when you can't proceed further due to some error.
- In contrast, `:ignore` should be used when stopping the server is the normal course of action.
- Returning `{:stop, reason, new_state}` from `handle_*` callbacks causes GenServer to stop the server process.
- If the termination is part of the standard workflow, you should use the atom `:normal` as the stoppage reason.
- If you're in `handle_call/3` and also need to respond to the caller before terminating, you can return `{:stop, reason, response, new_state}`. 

***You may wonder why you need to return a new state if you're terminating the process.*** The reason is that just before the termination, ***GenServer calls the callback function `terminate/2`, sending it the termination reason and the final state of the process.*** This can be useful if you need to perform cleanup. Finally, you can also stop the server process by invoking `GenServer.stop/3` from the client process. This invocation will issue a synchronous request to the server. The behaviour will handle the stop request itself by stopping the server process.

### 6.2.6 Process lifecycle

It's important to always be aware of how GenServer-powered processes tick and where (in which process) various functions are executed.

> ***Figure 6.1 is very clear!!!***

### 6.2.7 OTP-compliant processes

For various reasons, once you start building production systems, ***you should avoid using plain processes started with spawn. Instead, all of your processes should be so-called OTP-compliant processes.*** Such processes adhere to OTP conventions, they can be used in supervision trees (described in chapter 9), and errors in those processes are logged with more details.

