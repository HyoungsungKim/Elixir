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