# CH5 Concurrency primitives

> primitives : 기초 요소

## 5.1 Concurrency in Beam

- Fault-tolerance — Minimize, isolate, and recover from the effects of runtime errors.
- Scalability — Handle a load increase by adding more hardware resources without changing or redeploying the code.
- Distribution — Run your system on multiple machines so that others can take over if one machine crashes.

In BEAM, ***the unit of concurrency is a `process`*** : a basic building block that makes it possible to build scalable, fault-tolerant, distributed systems.

***Tasks should be as isolated from each other as possible.*** That’s exactly what the BEAM concurrency model does for us. Processes help us run things in parallel, allowing us to achieve scalability — the ability to address a load increase by adding more hardware power that the system automatically takes advantage of. Processes also ensure isolation, which in turn gives us ***`fault-tolerance` — the ability to localize and limit the impact of unexpected runtime errors that inevitably occur. If you can localize exceptions and recover from them, you can implement a system that truly never stops, even when unexpected errors occur.***

In BEAM, a process is a concurrent thread of execution. Two processes run concurrently and may therefore run in parallel, assuming at least two CPU cores are available. Unlike OS processes or threads, BEAM processes are lightweight concurrent entities handled by the VM, which uses its own scheduler to manage their concurrent execution.

you can create a large number of processes: the theoretical limit imposed by the VM is roughly ***134 million***

Running tasks in different processes improves the server’s reliability and fault-tolerance. ***BEAM processes are completely isolated;*** they share no memory, and a crash of one process won’t take down other processes. In addition, BEAM provides a means to detect a process crash and do something about it, such as restarting the crashed process. All this makes it easier to create systems that are more stable and can gracefully recover from unexpected errors, which inevitably occur in production.

## 5.2 Working with processes

>***Concurrency vs. parallelism***
>
>It’s important to realize that concurrency doesn't necessarily imply parallelism. Two concurrent things have independent execution contexts, but this doesn't mean they will run in parallel. If you run two CPU-bound concurrent tasks and you only have one CPU core, parallel execution can’t happen. You can achieve parallelism by adding more CPU cores and relying on an efficient concurrent framework. But you should be aware that concurrency itself doesn't necessarily speed things up.

```elixir
iex> run_query = 
	fn query_def ->
		Process.sleep(2000)
		"#{query_def} result"
	end
iex> run_query.("query 1")
"query 1 result"
iex> Enum.map(1..5, &run_query.("query #{&1}"))
["query 1 result", "query 2 result", "query 3 result", "query 4 result", "query 5 result"]
```

> #{variable} :  문자열 내부에 변수 대입
>
> &(capture operator) : It is used for anonymous function

The only thing you can do to try to make things faster is to run the queries concurrently.

### 5.2.1 Creating processes

To create a process, you can use the auto-imported `spawn/1` function:

```elixir
spawn(fn -> 
expression_1
...
expression_n
end)
```

The function `spawn/1` takes a zero-arity lambda that will run in the new process. After the process is created, `spawn` immediately returns, and the caller process’s execution continues. The provided lambda is executed in the new process and therefore runs concurrently. After the lambda is done, the spawned process exits, and its memory is released.

```elixir
iex> spawn(fn -> IO.puts(run_query.("query 1")) end)
#PID<0.48.0>
result of query 1
```

The funny-looking `#PID<0.48.0>` that’s returned by `spawn/1` is the identifier of the created process, often called a *pid*. This can be used to communicate with the process.

```elixir
#First, you’ll create a helper lambda that concurrently runs the query and prints the result:
iex> async_query.("query 1") = 
	fn query_def ->
		spawn(fn -> IO.puts(run_query.(query_def)) end
	end
iex> async_query.("query 1")
#PID<0.52.0>
result of query 1
```

***This code demonstrates an important technique: passing data to the created process.*** Notice that `async_query` takes one argument and binds it to the `query_def` variable. This data is then passed to the newly created process via the closure mechanism.

> Enum.each -> :ok 값을 리턴 함. 새로운 값을 만들지 않음(iterator처럼 반복)
>
> Enum.map -> 새로운 값을 만듬

Remember, processes are completely independent and isolated.

### 5.2.2 Message passing

When process A wants process B to do something, it sends an asynchronous message to B. Sending a message amounts to storing it into the receiver’s mailbox. The caller then continues with its own execution, and the receiver can pull the message in at any time and process it in some way. ***Because processes can’t share memory, a message is deep-copied when it’s sent.***

The process mailbox is a FIFO queue limited only by the available memory. The receiver consumes messages in the order received, and a message can be removed from the queue only if it’s consumed.

```elixir
send(pid, {:an, :arbitary, :term})
#The consequence of send is that a message is placed in the mailbox of the receiver.
```

```elixir
#On the receiver side, to pull a message from the mailbox, you have to use the receive expression:
receive do
	pattern_1 -> do_something
	pattern_2 -> do_something_else
end
```

If there are no messages in the mailbox, `receive` waits indefinitely for a new message to arrive.

> indefinitely : 무기한으로

The same thing happens if a message can’t be matched against provided pattern clauses:

If you don’t want `receive` to block, you can specify the `after` clause, which is executed if a message isn't received in a given time frame (in milliseconds):

#### Receive Algorithm

Recall from chapter 3 that an error is raised when you can’t pattern-match the given term. The `receive` expression is an exception to this rule.

> `reveice`는 pattern-matching안되면 계속 기다림

To summarize, receive tries to find the first (oldest) message in the process mailbox that can be matched against any of the provided patterns.

#### Synchronous sending

Sometimes a caller needs some kind of response from the receiver. There’s no special language construct for doing this. Instead, you must program both parties to cooperate using the basic asynchronous messaging facility.

The caller must include its own pid in the message contents and then wait for a response from the receiver. The receiver uses the embedded pid to send the response to the caller. You’ll see this in action a bit later, when we discuss server processes.

#### Collecting query results

```elixir
iex> async_query = 
	fn query_def ->
		caller = self()
		spawn(fn -> 
			send(caller, {:query_result, run_query.(query_def)})
		end)
	end
iex> Enum.each(1..5, &async_query.("query #{&1}"))
#capture operator is used because of variable
# "#"은 문자열에서 대입 위해 사용 됨 C/C++에서 printf("%d", 1) 여기서 %와 비슷한 역할...?
#Enum.each는 원소 순환 할 때 사용
```

> Pattern : {:query_result, run_query.(query_def)}를 caller에서 비동기로 실행. 여기서 caller는 자기자신(self())

```elixir
iex> get_result = 
	fn -> receive do
		{:query_result, result} -> result
	end
	end
# fn _-> get_result.() 이게 기가 막히네;;
iex> Enum.map(1..5, fn _-> get_result.() end)
["query 1 result", "query 2 result", "query 3 result", "query 4 result",
 "query 5 result"]
 #Results are nondeterministic order, but luckly, this time was deterministic
```

## 5.3 Stateful server process

Spawning processes to perform one-off tasks isn’t the only use case for concurrency. ***stateful server processes resemble objects.*** They maintain state and can interact with other processes via messages. But a process is concurrent, so multiple server processes can run in parallel. Server processes are an important concept in Elixir/Erlang systems, so we’ll spend some time exploring this topic.

### 5.3.1 Server processes

A `server process` is an informal name for a process that runs for a long time (or forever) and can handle various requests (messages). To make a process run forever, you have to use endless tail recursion.

```elixir
defmodule DatabaseServer do
	def start do
		sapwn(&loop/0)
	end
	
	defp loop do
		receive do
		
		end
		
		loop()
	end
end
```

`start/0` is the so-called `interface function` that’s used by clients to start the server process. When `start/0` is called, it creates the long-running process that runs forever. This is ensured in the private `loop/0` function, which waits for a message, handles it, and finally calls itself, thus ensuring that the process never stops. This loop isn't CPU-intensive. ***Waiting for a message puts the process in a suspended state and doesn't waste CPU cycles.***

When implementing a server process, it usually makes sense to put all of its code in a single module. The functions of this module generally fall into two categories: 

- interface : Interface functions are public and are executed in the caller process. They hide the details of process creation and the communication protocol.
- implementation :  Implementation functions are usually private and run in the server process.

```elixir
def loop do
    receive do
        {:run_query, caller, query_def} ->
        send(caller, {:query_def, run_query(query_def)})
        #결과를 클라이언트에게 다시 보냄
    end
loop()
end

defp run_query(query_def) do
	process.sleep(2000)
	"#{query_def} result"
end
```

Usually you want to hide these communication details from your clients. Clients shouldn't depend on knowing the exact structure of messages that must be sent or received. To hide this, it’s best to provide a dedicated interface function. Let’s introduce a function called ***`run_async/2` that will be used by clients to request the operation*** — in this case, a query execution — from the server. This function makes the clients unaware of message-passing details — they just call `run_async/2` and get the result.

```elixir
defmodule DatabaseServer do
	def get_result do
		receive do
			{:query_result, result} -> result
		after
			5000 -> {:error, :timeout}
		end
	end
end
```

#### Server process are sequential

It’s important to realize that a ***server process is internally sequential***. It runs a loop that processes one message at a time. Thus, if you issue five asynchronous query requests to a single server process, they will be handled one by one, and the result of the last query will come after 10 seconds.

A server process can be considered a synchronization point. ***If multiple actions need to happen synchronously, in a serialized manner, you can introduce a single process and forward all requests to that process, which handles the requests sequentially.***

You want to run multiple queries concurrently to get the result as quickly as possible. What can you do about it?

Assuming that the queries can be run independently, you can start a pool of server processes, and then for each query somehow choose one of the processes from the pool and have that process run the query. If the pool is large enough and you divide the work uniformly across each worker in the pool, you’ll parallelize the total work as much as possible.

```elixir
iex> pool = Enum.map(1..100, fn _ -> DatabaseServer.start() end)
```

All of these processes wait for a message, they’re effectively idle and don’t waste CPU time.

```elixir
iex> Enum.each(
	1..5,
	fn query_def ->
		server_pid = Enum.at(pool, :rand_uniform(100) - 1)
		DatabaseServer.run_async(server_pid, query_def)
	end
)
```

> Enum.at(A, index) : A의 index를 reference

You could do better if you used a map with process indexes as keys and pids as values; and there are other alternatives, such as using a round-robin approach. But for now, let’s stick with this simple implementation.

```elixir
iex> Enum.map(1..5, fn _ -> DataBaseServer.get_result() end)
```

### 5.3.2 Keeping a process state

Server processes open the possibility of keeping some kind of process-specific state. For example, when you talk to a database, you need a connection handle that’s used to communicate with the server. If your process is responsible for TCP communication, it needs to keep the corresponding socket.

To keep state in the process, you can extend the loop function with additional argument(s).

```elixir
def start do
	spawn(fn ->
		initial_state = ...
		loop(initial_state)
	end)
end

defp loop(state) do
	...
	loop(state)
end
```

### 5.3.3 Mutable state

So far, you've seen how to keep constant process-specific state. It doesn’t take much to make this state mutable. Here’s the basic idea:

```elixir
def loop(state) do
	new_state =
		receive do
			msg1 ->
			...
			msg2 ->
			...
		end
	loop(new_state)
end
```

This is a typical stateful server technique.

By sending messages to a process, a caller can affect its state and the outcome of subsequent requests handled in that server.

```elixir
defmodule Calculator do
    defp loop(current_value) do
	new_value = 
		receive do
			#send호출하고 current_value 반환
			{:value, caller} ->
			send(caller, {:response, current_value})
			current_value
			
			#일치 하는 패턴에 따라 반환 값 달라짐
			{:add, value} -> current_value + value
			{:sub, value} -> current_value - value
			{:mul, value} -> current_value * value
			{:div, value} -> current_value / value
			
			#일치하는 패턴 없을때 에러 출력하고 current_value 반환
			invalid_request -> 
				IO.puts("invalid request #{inspect invalid_request}")
				current_value
		end
		loop(new_value)
    end
end
```

Unlike a :value message handler, arithmetic operation handlers don’t send responses back to the caller. This makes it possible to run these operations asynchronously.

Implement the interface functions that will be used by clients.

```elixir
def start do
	spawn(fn -> loop(0) end)
end

def value(server_pid) do
	send(server_pid, {:value, self()})
	receive do
		{:response, value} -> value
	end
end

def add(server_pid, value), do: send(server_pid, {:add, value})
def sub(server_pid, value), do: send(server_pid, {:sub, value})
def mul(server_pid, value), do: send(server_pid, {:mul, value})
def div(server_pid, value), do: send(server_pid, {:div, value})
```

> send로 응답 요청하고 받으면 receive로 응답 확인

Keep in mind that the server handles messages in the order received, so requests are handled in the proper order.

#### Refactoring The Loop

As you introduce multiple requests to your server, the loop function becomes more complex. If you have to handle many requests, it will become bloated, turning into a huge switch/case -like expression.
You can refactor this by relying on pattern matching and moving the message handling to a separate multiclause function. This keeps the code of the loop function very simple:

```elixir
defp loop(current_value) do
	new_value = 
		receive do
			message -> process_message(current_value, message)
		end
		
	loop(new_value)
end

defp process_message(current_value, {:value, caller}) do
	send(caller, {:response, current_value})
	current_value
end
```

### 5.3.4 Complex states

State is usually much more complex than a simple number. But the technique remains the same — ***you keep the mutable state using the private loop function.***

Let's look at this technique using the TodoList abstraction developed in chapter 4. First, let's recall the basic usage of the structure:

```elixir
# ~: 정규 표현식 만듬(generate regular expression)
iex(1)> todo_list = TodoList.new() |>
	TodoList.add_entry(%{date: ~D[2018-12-19], title: "Dentist:"}) |>
	TodoList.add_entry(%[date: ~D[2018-12-20], title: "Shopping") |>
	TodoList.add_entry(%[date: ~D[2018-12-19], title: "Movies"})
iex(2) TodoList.entries(todo_list, ~D[2018-12-19])
[
	%{date: ~D[2018-12-19], id: 1, title: "Dentist"},
	%{date: ~D[2018-12-19], id: 3, title: "Movies"}
]
```

```elixir
defmodule TodoServer do
	def start do
		spawn(fn -> loop(TodoList.new()) end)
	end
	
	defp loop(todo_list) do
		new_todo_list = 
			receive do
				message -> process_message(todo_list, message)
			end		
		loop(new_todo_list)
	end
	
	#서버에 요청하면
	def add_entry(todo_server, new_entry) do
		send(todo_server, {:add_entry, new_entry})
	end
	
	#서버에서 이 함수 실행시켜서 TodoList 모듈 호출 해서 add_entry 실행
	defp process_message(todo_list, {:add_entry, new_entry})
		TodoList.add_entry(todo_list, new_entry)
	end
	
	def entries(todo_server, date) do
		send(todo_server, {:entries, self(), date})
		
		receive do
			{:todo_list, entries} -> entries
		after 
			5000 -> {:error, :timeout}
		end
	end
	
	defp process_message(todo_list, {:entries, caller, date}) do
		send(caller, {:todo_entries, TodoList.entries(todo_list, date)})
		todo_list
	end
end
```

#### Concurrent vs Functional Approach

But you shouldn't abuse processes to avoid using the functional approach of transforming immutable data. ***The data should be modeled using pure functional abstractions, just as you did with `TodoList` .***

### 5.3.5 Registered processes

To make process A send messages to process B, you have to bring the pid of process B to process A. In this sense, a pid resembles a reference or pointer in the OO world. Sometimes it can be cumbersome to keep and pass pids.

If you know there will always be only one instance of some type of server, you can give the process a local name and use that name to send messages to the process.

```elixir
iex> Process.reguster(self(), :some_name)
#Process 이름이 :some_name으로 지정 됨
```

The following rules apply to registered names:

- The name can only be an atom.
- A single process can have only one name.
- Two processes can't have the same name.

***If these rules aren't satisfied, an error is raised.***   

## 5.4 Runtime considerations

It’s important to understand some of its internals.

### 5.4.1 A process is sequential

***Although multiple processes may run in parallel, a single process is always sequential*** — it either runs some code or waits for a message. If many processes send messages to a single process, that single process can significantly affect overall throughput.

```elixir
defmodule Server do
	def start do
		spawn(fn -> loop() end)
	end
	
	def send_msg(server, message) do
		send(server, {self(), message})
		receive do
			{:response, response} -> response
		end		
	end
	
	def loop do
		receive do
			{caller, message} -> Process.sleep(1000)
			send(caller, {:response, message})
		end		
		loop()
	end
end
```

The echo server can handle only one message per second. Because all other processes depend on the echo server, they’re constrained by its throughput. Once you identify the bottleneck, you should try to optimize the process internally. ***The goal is to make the server handle messages at least as fast as they arrive.***

If you can't make message handling fast enough, ***you can try to split the server into multiple processes, effectively parallelizing the original work and hoping that doing so will boost performance on a multicore system.*** This should be your last resort, though. Parallelization isn't a remedy for a poorly structured algorithm.

### 5.4.2 Unlimited process mailboxes

If a process constantly falls behind, meaning messages arrive faster than the process can handle them, the mailbox will constantly grow and increasingly consume memory. Single slow process may cause an entire system to crash by consuming all the available memory. large mailbox contents cause performance slowdowns.

For each server process, ***you should introduce a match-all receive clause that deals with unexpected kinds of messages.*** Typically, you'll log that a process has received the unknown message, and do nothing else about it:

```elixir
def loop
	receive
        {:message, msg} -> do_something(msg)
        other -> log_unknown_message(other)
	end
	
	loop()
end
```

### 5.4.3 Shared-nothing concurrency

Processes share no memory. Thus, sending a message to another process results in a deep copy of the message contents:

```elixir
send(target_pid, data) #Deep-copied
```

closing on a variable from a spawn also results in deep-copying the closed variable:

```elixir
spawn(fn -> some_fun(data) end)	#Result in a deep copy of the data variable
```

Deep-copying is an in-memory operation, so it should be reasonably fast, and occasionally sending a big message shouldn't present a problem. But having many processes frequently send big messages may affect system performance.

***A special case where deep-copying doesn't take place involves binaries (including strings) that are larger than 64 bytes.*** This can be useful when you need to send information to many processes, and the processes don’t need to decode the string.

You may wonder about the purpose of shared-nothing concurrency.

- First, it simplifies the code of each individual process. Because processes don't share memory, you don't need complicated synchronization mechanisms such as locks and mutexes.
- Another benefit is overall stability: one process can't compromise the memory of another. This in turn promotes the integrity and fault-tolerance of the system.
- Finally, shared-nothing concurrency makes it possible to implement an efficient garbage collector. Because processes share no memory, garbage collection can take place on a process level.

> 64 bytes보다 크면 deep-copy 안함(프로세스 내부에서 garbage collection 구현하기 위해서)

### 5.4.4 Scheduler inner workings

Each BEAM scheduler is in reality an OS thread that manages the execution of BEAM processes.

In general, you can assume that there are `n` schedulers that run `m` processes, with `m` most often being significantly larger than `n`. This is called m:_n_threading.

Internally, each scheduler maintains a run queue, which is something like a list of BEAM processes it's responsible for. Each process gets a small execution window, after which it's preempted and another process is executed. The execution window is approximately 2,000 function calls (internally called reductions).

> preempted : 선매권에 의하여 획득하다.
>
> n개의 스케줄러가 m개의 프로세스 관리 -> 1개의 스케줄러가 x개의 프로세서 관리하는데 스캐줄러가 n개 있음. x*n=m

There are some special cases when a process will implicitly yield execution to the scheduler before its execution time is up. The most notable situation is when using `receive`. Another example is a call to the `Process.sleep/1` function. In both cases, the process is suspended, and the scheduler can run other processes.

Another important case of implicit yielding involves I/O operations, which are internally executed on separate threads called `async` threads. ***When issuing an I/O call, the calling process is preempted, and other processes get the execution slot. After the I/O operation finishes, the scheduler resumes the calling process.***

***A great benefit of this is that your I/O code looks synchronous, while under the hood it still runs asynchronously.*** By default, BEAM fires up 10 async threads, but you can change this via the +A n Erlang flag.