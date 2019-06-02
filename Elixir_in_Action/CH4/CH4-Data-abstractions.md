# Data Abstractions

In a typical OO language, the basic abstraction building blocks are classes and objects. But in Elixir Instead of classes, you use modules, which are collections of functions. Instead of calling methods on objects, you explicitly call module functions and provide input data via arguments.

```elixir
String.upcase("a string")
```

Another big difference from OO languages is that data is immutable. ***To modify data, you must call some function and take its result into a variable;***

```elixir
iex(1)> list = []
iex(2)> list = List.insert_at(list, -1, :a)	#[:a]
iex(3)> list = List.insert_at(list, -1, :b) #[:a, :b]
iex(4)> list = List.insert_at(list, -1, :c) #[:a, :b, :c]
```

The important thing to notice in both Elixir snippets is that the module is used as the abstraction over the data type. 

## 4.1 Abstracting with modules

```elixir
iex(1)> days = 
MapSet.new() |>
	MapSet.put(:monday)	|>
	MapSet.put(:tuesday)
iex(2) MapSet.member?(days, :monday)	#true
```

Notice the `new/0` function that creates an empty instance of the abstraction.

### 4.1.1 Basic abstraction

The basic version of the to-do list will support the following features:

- Creating a new data abstraction
- Adding new entried
- Querying the abstraction

>self-explanatory : 자명한, 설명이 필요없는
>
>instantiate : 예를 들어 설명하다.

### 4.1.2 Compressing abstractions

The point of this refactoring is to illustrate that the code organization isn't that different from an OO approach. You use different tools to create abstractions (stateless modules and pure functions instead of classes and methods), but the general idea is the same.

> refactoring : 코드의 가독성을 높이고 유지보수를 편하게 함.

### 4.1.3 Structing data with maps