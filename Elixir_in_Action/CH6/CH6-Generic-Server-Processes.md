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

