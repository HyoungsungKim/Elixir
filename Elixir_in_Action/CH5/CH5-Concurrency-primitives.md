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

