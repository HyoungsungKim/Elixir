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

If you want to extend an entry with another attribute — such as time — you must change the signature of the function, which will in turn break all the clients. Moreover, you have to change every place in the implementation where this data is being propagated. ***An obvious solution to this problem is to somehow combine all entry fields as a single data abstraction.***  The most common way of doing this in Elixir is to use maps, with field names stored as keys of the atom type.

### 4.1.4 Abstracting with structs

Elixir provides a facility called `structs` that allows you to specify the abstraction structure up front and bind it to a module.

```elixir
defmodule Fraction do
	defstruct a: nil, b: nil
end
```

A keyword list provided to defstruct defines the struct's fields together with their initial values.

```elixir
iex(1)> one_half = %Fraction{a:1, b:2}
%Fraction{a: 1, b: 2}
iex(2)> one_half.a
1
iex(3)> one_half.b
2
iex(4)> %Fraction{a :a, b: b} = one_half
%Fraction{a: 1, b: 2}
iex(5)> %Fraction{} = %{a: 1, b: 2}
** (MatchError) no match of right hand side value: %{a: 1, b: 2}
```

There’s a tight relation between structs and modules. ***A struct may exist only in a module, and a single module can define only one struct.***

In a pattern match, you need to specify only the fields you’re interested in, ignoring all other fields.

```elixir
#Update structure
iex(6)> one_quarter = %Fraction{one_half | b: 4}
%Fraction{a : 1, b : 4}
```

The benefit of pattern matching is that the input type is enforced. If you pass anything that isn’t a fraction instance, you’ll get a match error.

```elixir
def value(%Fraction{a: a, b: b}) do
    fraction.a/fraction.b    
    # same with : a/ b
end
```

***This code is arguably clearer, but it will run slightly more slowly than the previous case where you read all fields in a match.*** This performance penalty shouldn't make much of a difference in most situations, so you can choose the approach you find more readable.

#### Struct vs Maps

You should always be aware that structs are in reality just maps, so they have the same characteristics with respect to performance and memory usage. But a struct instance receives special treatment. Some things that can be done with maps don’t work with structs. For example, ***you can’t call the Enum function on a struct:***

```elixir
iex(1)> one_half = Fraction.new(1, 2)
iex(2)> Enum.to_list(one_half)
** (Protocol.UndefinedError) protocol Enumerable not implemented for %Fraction{a: 1, b: 2}
iex(3)> Enum.to_list(%{a: 1, b: 2})
[a: 1, b: 2]
iex(4)> Map.to_list(one_half)
[__struct__: Fraction, a: 1, b: 2]
iex(5)> %Fraction{} = %{a: 1, b: 2}
```

***The struct field has an important consequence for pattern matching. A struct pattern can’t match a plain map:***

```elixir
iex(5)> %Fraction{} = %{a: 1, b: 2}
** (MatchError) no match of right hand side value: %{a: 1, b: 2}
```

But a plain map pattern can match a struct

```elixir
iex(5)> %{a: a, b: b} = %Fraction{a: 1, b: 2}
%Fraction{a: 1, b: 2}
iex(6)> a
1
iex(7)> b
2
```

This is due to the way pattern matching works with maps. Remember, ***all fields from the pattern must exist in the matched term.*** When matching a map to a struct pattern, this isn’t the case, because %Fraction{} contains the field struct, which isn’t present in the map being matched.

> map = struct 가능
>
> struct = map 불가능
>
> struct는 module에 의존하기 때문에 matched term에 존재하지 않음.

The opposite works, because you match a struct to the %{a: a, b: b} pattern. Because all these fields exist in the Fraction struct, the match is successful.

#### Records

This is a facility that lets you use tuples and still be able to access individual elements by name.

Given that they’re essentially tuples, ***records should be faster than maps*** (although the difference usually isn't significant in the grand scheme of things). On the flip side, the usage is more verbose, and it’s not possible to access fields by name dynamically.

> map 등장 이후로 잘 안쓰임. 하지만 erlang에서는 많이 쓰이고 있음

### 4.1.5 Data transparency

***It’s important to be aware that data in Elixir is always transparent.*** Clients can read any information from your structs (and any other data type), and there’s no easy way of preventing that. In that sense, encapsulation works differently than in typical OO languages. In Elixir, modules are in charge of abstracting the data and providing operations to manipulate and query that data, but ***the data is never hidden.***

```elixir
iex(1)> todo_list = ToDoList.new() |>
		ToDoList.add_entry(%{date: ~D[2018-12-19], title: "Dentist"})
%{~D[2018-12-19] => [%{date: ~D[2018-12-19], title: "Dentist"}]}
```

> map: %{key => value}

One final thing you should know, related to data inspection, is the `IO.inspect/1` function. This function prints the inspected representation of a structure to the screen and returns the structure itself. 

## 4.2 Working with hierarchical data

you’ll extend the TodoList abstraction to provide basic CRUD support.

- C : Create
- R : Read
- U : Update
- D : Delete

### 4.2.1 Generating IDs

- Transform the to-do list into a struct
- Use the entry's ID as the key

### 4.2.2 Updating entries

The function will accept an ID value for the entry and an updater lambda. This will work similarly to Map.update. The lambda will receive the original entry and return its modified version.

#### Fun with pattern matching

`update_entry/3` works fine, but it’s not quite bulletproof. The updater lambda can return any data type, possibly corrupting the entire structure.

You can go a step further and assert that the ID value of the entry hasn't been changed in the lambda:

```elixir
old_entry_id = old_entry.id
new_entry = %{id: ^old_entry_id} = updater_fun.(old_entry)
```

`^`var in a pattern match means you’re matching on the value of the variable.

> 변수에 새로운 값이 대입되는 것을 원치 않을 수도 있습니다. 이러한 상황에서는 핀 연산자 `^`를 사용해야 합니다. (elixir school)
>
> 여기서 undater_fun함수가 %{id: ^old_entry_id}의 값과 다른 값이 나오면 에러 발생

```elixir
def update_entry(todo_list, %{} = new_entry) do
	update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
end
```

### 4.2.3 Immutable hierarchical updates

If you have hierarchical data, you can’t directly modify part of it that resides deep in its tree. Instead, you have to walk down the tree to the particular part that needs to be modified, and then transform it and all of its ancestors. 

#### Provided Helpers

Remember, to update an element deep in the hierarchy, you have to walk to that element and then update all of its parents. To simplify this, Elixir offers support for more elegant deep hierarchical updates.

```elixir
iex> todo_list = % {
	1 => %{date: ~D[2018-12-19], title: "Dentist"},
	2 => %{date: ~D[2018-12-20], title: "Shopping"},
	3 => %{date: ~D[2018-12-19], title: "Movie"}
}

iex> put_in(todo_list[3].title, "Theater")
%{
	1 => %{date: ~D[2018-12-19], title: "Dentist"}
	2 => %{date: ~D[2018-12-20], title: "Shopping"},
	3 => %{date: ~D[2018-12-19], title: "Theater"}
}
```

It’s also worth noting that Elixir provides similar alternatives for data retrieval and updates in the form of the `get_in/2`, `update_in/2`, and `get_and_update_in/2` macros.

>```elixir
>iex> steve = %Example.User{name: "Steve"}
>#Example.User<name: "Steve", roles: [...], ...>
>iex> sean = %{steve | name: "Sean"}
>#Example.User<name: "Sean", roles: [...], ...>
>```
>
>***`|` operator is used to correct struct***

### 4.2.4 Iterative updates

To build the to-do list iteratively, you’re relying on `Enum.reduce/3.` Recall from chapter 3 that reduce is used to transform something enumerable to anything else. In this case, you’re transforming a raw list of `Entry` instances into an instance of the `Todo-List` struct.

## 4.3 Polymorphism with protocols

> 이미 정의된 모듈에 자신이 원하는 type이나 struct 추가하는 느낌?
>
> //` in function parameter means default value

`Polymorphism` is a runtime decision about which code to execute, based on the nature of the input data. In Elixir, the basic (but not the only) way of doing this is by using the language feature called `protocols`.

```elixir
Enum.each([1, 2, 3], &IO.inspect/1)
Enum.each(1..3, &IO.inspect/1)
Enum.each({a: 1, b: 2}, &IO.inspect/1)
```

### 4.3.1 Protocol basics

A `protocol` is a module in which you declare functions without implementing them.

```elixir
defprotocol String.Chars do	#Definition of the protocol
	def to_string(thing)	#Declaration of protocol function
end
```

### 4.3.2 Implementing a protocol

```elixir
defimpl String.Chars, for: Integer do
	def to_string(term) do
		Integer.to_string(term)
	end
end
```

The `for: Type` part deserves some explanation. The type is an atom and can be any of following aliases: `Tuple`, `Atom`, `List`, `Map`, `BitString`, `Integer`, `Float`, `Function`, `PID`, `Port`, or `Reference`. These values correspond to built-in Elixir types.

In addition, the alias `Any` is allowed, which makes it possible to specify a fallback implementation.

> fallback : 대비책

You can place the protocol implementation anywhere in your own code, and the runtime will be able to take advantage of it.

### 4.3.3 Built-in protocols

[Why are there two kinds of functions in Elixir?](https://stackoverflow.com/questions/18011784/why-are-there-two-kinds-of-functions-in-elixir)

Enumerable : Enumerable is `protocols`, enum is `module`: Enumerable protocol used by `Enum` and `Stream` modules

```elixir
Enum.map([1,2,3], &(&1 * 2))
#internal implementation
def map(enumerable, fun) do
	reducer = fn x, acc -> {:cont, [fun.(x) | acc]} end
	Enumerable.reduce(enumerable, {:cont, []}, reducer) |> elem(1) |> :listes.reverse()
end
```

Stream : Functions for creating and composing streams. The `stream` module allows us to map the range, without triggering its enumeration:

```elixir
iex> range = 1..5
iex> Enum.map(range, &(&1 * 2))
[2, 4, 6, 8, 10]

iex> range = 1..3
iex> stream = Stream.map(range, &(&1 * 2))
iex> Enum.map(stream, &(&1 + 1))
[3, 5, 7])
```

We say the functions in `Stream` are ***lazy*** and the functions in `Enum` are *eager*.

Due to their laziness, streams are useful when working with large (or even infinite) collections.

Collectable : A protocol to traverse data structures. The `Enumerable` protocol is useful to take values out of a collection. In order to support a wide range of values, the functions provided by the `Enumerable` protocol do not keep shape. The Collectable module was designed to fill the gap left by the `Enumerable` protocol.

#### Collectable to-do list

```elixir
defimpl Collectable, for: TodoList do
	def into(original) do
		{original, &into_callback/2}
	end
	
	defp into_callback(todo_list, {:cont, entry}) do
		TodoList.add_entry(todo_list, entry)
	end
	defp into_callback(todo_list, :done), do: todo_list
	defp into_callback(todo_list, :halt), do: ok
end
```

> & is used to capture function [Understanding the & (capture operator) in Elixir](https://dockyard.com/blog/2016/08/05/understand-capture-operator-in-elixir)