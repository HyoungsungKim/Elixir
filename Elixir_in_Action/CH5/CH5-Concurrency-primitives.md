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