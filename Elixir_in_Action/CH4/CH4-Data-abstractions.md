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