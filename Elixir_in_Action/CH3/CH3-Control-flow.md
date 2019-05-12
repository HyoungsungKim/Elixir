# CH3 Control flow

This chapter covers

- Understanding pattern matching
- Working with multiclause functions
- Using conditional expressions
- Working with loops

It’s time to look at some typical low-level idioms of the language.

## 3.1 Pattern matching

As mentioned in chapter 2, the = operator isn't an assignment. Instead, when I wrote a = 1, I said variable a was bound to the value 1. ***The operator = is called the match operator, and the assignment-like expression is an example of pattern matching.***

### 3.1.1 The match operator

```elixir
iex(1)> person = {"Bob", 25}
```

The ***left side is called a pattern***, whereas on the ***right side you have an expression that evaluates*** to an Elixir term.

### 3.1.2 Matching tuples

```elixir
iex(1)> {name, age} = {"Bob", 25}
iex(2)> name
Bob
iex(3)> age
25
```

This feature is useful when you call a function that returns a tuple and you want to bind individual elements of that tuple to separate variables.

```elixir
iex(4)> {date, time} = :calendar.local_time()
{{2019, 5, 12}, {23, 20, 19}}
iex(5)> {year, month, day} = date
{2019, 5, 12}
iex(6)> {hour, minute, second} = time
{23, 20, 19}
```

### 3.1.3 Matching constants

```elixir
iex(1)> 1 = 1
1
iex(2)> 1 = 2
** (MatchError) no match of right hand side value: 2
```

This example doesn't have much practical benefit, but it illustrates that you can place constants to the left of =, which proves that = is not an assignment operator.

The following snippet creates a tuple that holds a person’s name and age:

```elixir
iex(1)> person = {:person, "Bob", 25}
iex(2)> {:person, name, age} = person
{:person, "Bob", 25}
iex(3)> name
"Bob"
iex(4)> {:person1, name, age} = person
** (MatchError) no match of right hand side value: {:person, "Bob", 25}
```

Many functions from Elixir and Erlang return either {:ok, result} or {:error, reason}.

### 3.1.4 Variables in pattern

```elixir
iex(1)> {_date, time} = :calendar.local_time()
iex(13)> _date
warning: the underscored variable "_date" is used after being set. A leading underscore indicates that the value of the variable should be ignored. If this is intended please rename the variable to remove the underscore
  iex:13

{2019, 5, 12}
```

The _date is regarded as an anonymous variable, because its name starts with an underscore. Technically speaking, you could use that variable in the rest of the program, but the compiler will emit a warning.

A variable can be referenced multiple times in the same pattern. In the following expressions, you expect an RGB triplet with the same number for each component:

```elixir
iex(14)> {amount, amount, amount} = {127, 127, 127}
{127, 127, 127}

iex(15)> {amount, amount, amount} = {127, 127, 1}
** (MatchError) no match of right hand side value: {127, 127, 1}

iex(15)> {amount, amount, amount} = {1, 1, 1}
{1, 1, 1}
```

***{amount, amount, amount} have to be matched with three identical elements***

***Occasionally, you’ll need to match against the contents of the variable.***  For this purpose, the pin operator (^) is provided. This is best explained with an example:

```elixir
iex(1)> expected_name = "Bob"
"Bob"
iex(2)> {^expected_name, _} = {"Bob", 25}
{"Bob", 25}
iex(3)> {^expeceted_name, _} = {"Alice", 30}
** (MatchError) no match of right hand side value: {"Alice", 25}
```

This technique is used less often and is mostly relevant when you need to construct the pattern at runtime.

### 3.1.5 Matching lists

```elixir
iex(1)> [first, second, third] = [1, 2, 3]
[1, 2, 3]
iex(21)> [1, second, second] = [1, 2, 3]
** (MatchError) no match of right hand side value: [1, 2, 3]    
iex(21)> [1, second, second] = [1, 2, 2]
[1, 2, 2]
```

Matching lists is more often done by relying on their recursive nature. Recall from chapter 2 that each non-empty list is a recursive structure that can be expressed in the form [head | tail]. 

```elixir
iex(3)> [head | tail] = [1, 2, 3]
iex(4)> head
1
iex(5)> tail
[2, 3]
iex(6)> [min | _] = Enum.sort([3, 2, 1])
iex(7)> min
1
```

### 3.1.6 Matching maps

To match a map, the following syntax can be used:

```elixir
iex(1)> %{name: name, age: age} = %{name: "Bob", age: 25}
iex(2)> name
"Bob"
iex(3)> age
25
iex(4)> %{age: age} = %{name: "Bob", age: 25}
iex(5)> age
25
```

> Similar with dictionary in python

Of course, a match will fail if the pattern contains a key that’s not in the matched term:

```elixir
iex(6)> %{age: age, works_at: works_at} = %{name: "Bob", age: 25}
** (MatchError) no match of right hand side value
```

### 3.1.7 Matching bitstrings and binaries

syntax. Recall that a bitstring is a chunk of bits, and a binary is a special case of a bitstring that's always aligned to the byte size.

```elixir
iex(1)> binary = <<1, 2, 3>>
<<1, 2, 3>>
iex(2) <<b1, b2, b3>> = binary
<<1, 2, 3>>
iex(3)> b1
1
iex(4)>b2
2
iex(5)>b3
3
iex(6)> <<b1, rest::binary>> = binary
<<1, 2, 3>>
iex(7)> b1
1
iex(8)> rest
<<2, 3>>
```

rest::binary states that you expect an arbitrary-sized binary. You can even extract separate bits or groups of bits. The following example splits a single byte into two 4-bit values:

```elixir
iex(9)> <<a::4, b::4>> = <<155>>
<<155>>
#155 = 10011011 (128 + 16 + 8 + 2 + 1)
iex(9)> a
9
#1001
iex(10)> b
11
#1011
```

#### Matching Binary Strings

```elixir
iex(1)> <<b1, b2, b3>> = "ABC"
iex(2)> b1
65
iex(3)> b2
66
# Extract string
iex(4)> command = "ping www.example.com"
"ping www.example.com"
iex(5)> "ping " <> url = command
"ping www.example.com"
iex(6) url
"www.example.com"
```

When you write "ping " <> url = command, you state the expectation that a command variable is a binary string starting with "ping ". ***If this matches, the rest of the string is bound to the variable url.***

### 3.1.8 Compound matches

