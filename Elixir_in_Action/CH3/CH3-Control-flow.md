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

Patterns can be arbitrarily nested, as in the following contrived example:

```elixir
iex(1)> [_, {name, _}, _] = [{"Bob", 25}, {"Alice", 30}, {"John", 35}]
```

Another interesting feature is match chaining.

```elixir
#pattern = expression
iex(2)> a = 1 + 3
4
iex(3)> a = (b = 1 + 3)
4
#elegance example
iex(4)> date_time = {_, {hour, _, _}} = :calaendar.local_time()
```

## 3.2 Matching with functions

The pattern-matching mechanism is used in the specification of function arguments.

```elixir
defmodule Rectangle do
    def area({a,b}) do
        a * b
    end
end
```

### 3.2.1 Multiclause functions

Elixir allows you to overload a function by specifying multiple clauses. If you provide multiple definitions of the same function with the same arity, it’s said that the function has multiple clauses

```elixir
defmodule Geometry do
    def area({:rectangle, a, b}) do
        a * b
    end

    def area({:square, a}) do
        a * a
    end

    def area({:circle, r}) do
        r * r * 3.14
    end
end
```

Same area function but pattern is different

Recall from chapter 2 that you can create a function value with the capture operator, &:

```elixir
&Module.fun/arity
iex(1) fun = &Geometry.area/1
iex(2)fun.({:circle, 4})
50.24
```

Notice that the area(unknown) clause works only for area/1. If you pass more than one argument, this clause won’t be called. 

```elixir
iex(2)> Geometry_invalid_input.area({:triangle, 1, 2,3})
{:error, {:unknown_shape, {:triangle, 1, 2, 3}}}
iex(3)> Geometry_invalid_input.area({:triangle,:circle})
{:error, {:unknown_shape, {:triangle, :circle}}}
iex(4)> Geometry_invalid_input.area({:triangle,:circle}, {:hi})
** (UndefinedFunctionError) function Geometry_invalid_input.area/2 is undefined or private. Did you mean one of:
	* area/1
Geometry_invalid_input.area({:triangle, :circle}, {:hi})
```

***One final note: you should always group clauses of the same function together, instead of scattering them in various places in the module. ***

### 3.2.2 Guards

Let’s say you want to write a function that accepts a number and returns an atom *:negative*, *:zero*, or *:positive*, depending on the number’s value. ***Elixir gives you a solution for this in the form of guards.***

```elixir
defmodule TestNum do
    def test(x) whem x < 0 do
        :negative
    end

    def test(0), do: :zero
    
    #Same with
    #def test(0) do
    #	:zero
    #end
    
    def test(x) when x > 0 do
        :postive
    end
end

```

The guard is a logical expression that places further conditions on a clause. The first clause will be called only if you pass a negative number, and the last one will be called only if you pass a positive number, as demonstrated in this shell session:

```elixir
iex(4)> TestNum.test('a')
:postive
```

The explanation lies in the fact that Elixir terms can be compared with the operators < and >, even if they’re not of the same type. In this case, the type ordering determines the result:

```elixir
#Guards ver
#is_number(x)
defmodule TestNum do
    def test(x) when is_number(x) and x < 0 do
        :negative
    end

    def test(0), do: :zero

    def test(x) when is_number(x) and x > 0 do
        :postive
    end
end
```

***If an error is raised from inside the guard, it won’t be propagated, and the guard expression will return false***

### 3.2.3 Multiclause lambdas

Anonymous functions (lambdas) may also consist of multiple clauses.

```elixir
iex(1)> double = fn x -> x*2 end
iex(2)> double.(3)
6
```

The general lambda syntax has the following shape:

```elixir
fn
    pattern_1, pattern_2 -> 
    	...
    pattern_3, pattern_4 ->
    	...
...
end
```

```elixir
#Reimplement using lambda
iex(1)> test_num = 
fn
	x when is_number(x) and x < 0 ->
		:negative	
	0-> :zero	
	x when is_number(x) and x > 0 -> 
		:postive
end
iex(26)> test_num.(1)
:postive
iex(27)> test_num.(-1)
:negative
iex(28)> test_num.(0)
:zero
iex(29)> test_num.("Hello world")
** (FunctionClauseError) no function clause matching in :erl_eval."-inside-an-interpreted-fun-"/1
    The following arguments were given to :erl_eval."-inside-an-interpreted-fun-"/1:
        # 1
        "Hello world"
iex(29)> test_num.(:atom)
** (FunctionClauseError) no function clause matching in :erl_eval."-inside-an-interpreted-fun-"/1
    The following arguments were given to :erl_eval."-inside-an-interpreted-fun-"/1:
        # 1
        :atom
```

***Notice that there’s no special ending terminator for a lambda clause***  The clause ends when the new clause is started (in the form pattern →) or when the lambda definition is finished with end.

## 3.3 Conditionals

### 3.3.1 Branching with multiclause functions

```elixir
defmodule TestNum do
    def test(x) when x < 0, do: :negative
    def test(0), do: : zero
    def test(x), do: :postive
end
#def name(parameter) condition, do
#...
#end
```

In the following example, a multiclause is used to test whether a given list is empty:

```elixir
defmodule TestList do
def empty?([]), do: :true
def empty?([_|_]). do: :false
end

iex(31)> TestList.empty?([])
true
iex(32)> TestList.empty?([_])
** (CompileError) iex:32: invalid use of _. "_" represents a value to be ignored in a pattern and 
cannot be used in expressions

iex(32)> TestList.empty?(_)
** (CompileError) iex:32: invalid use of _. "_" represents a value to be ignored in a pattern and cannot be used in expressions

iex(32)> TestList.empty?([1|2])
false
iex(33)> TestList.empty?([1,2])
false
```

The first clause matches the empty list, whereas the second clause relies on the [head | tail] representation of a non-empty list.

```elixir
iex(1)> defmodule Polymorphic do
def double(x) when is_number(x), do: 2 * x
def double(x) when is_binary(x), do: x <> x
#return "xx"
#iex(1)> "Hello " <> "World"
#iex(2)> "Hello World"
end
#iex(1)> "Hello " <> x = "Hello World"
#Hello World
#iex(2)> x
#World
iex(2)> Polymorphic.double(3)
6
iex(3)> Polymorphic.double("Jar")
"JarJar"
```

The power of multiclauses starts to show in recursions. The resulting code seems declarative and is devoid of redundant ifs and returns

> devoid : ~이 전혀 없는
>
> declarative : 서술문의

```elixir
iex(1)> defmodule Fact do
def fact(0), do: 1
def fact(n), do: n * dact(n - 1)
end
iex(2)> Fact.fact(1)
1
iex(3)> Fact.fact(3)
6
```

```elixir
defmodule ListHelper do
def sum([]), do: 0
def sum([head|tail]), do: head + sum(tail)
end
iex(1)> ListHelper.sum([])
iex(2)> ListHelper.sum([1,2,3])
6
```

But the multiclause approach forces you to layer your code into many small functions and push the conditional logic deeper into lower layers. The underlying pattern-matching mechanism makes it possible to implement all kinds of branchings that are based on values or types of function arguments.

> imperative : 반드시 해야하는

### 3.2.2 Classical branching constructs

#### If and Unless

```elixir
if condition do
...
else
...
end
```

***Recall that everything in Elixir is an expression that has a return value.***

```elixir
def max(a, b) do 
#if a >= b is true return a
	if a >= b, do: a, else: b
end

def max(a, b) do
#if a >= b is false return b
	unless a >= b, do:b, else: a
end
```

#### COND

The cond macro can be thought of as equivalent to an if-else-if pattern. It takes a list of expressions and executes the block of the first expression that evaluates to a truthy value:

```elixir
cond do
	expression_1 ->
	...
	expression_2 ->
	...
end
```

The result of cond is the result of the corresponding executed block. If none of the conditions is satisfied, ***cond raises an error.***

```elixir
def max(a,b) do
	cond do
        a >= b -> a
        true -> b #Default clause
	end
end
```

#### CASE

```elixir
case expression do
    pattern_1 ->
    ...
    pattern_2 ->
    ...
...
end
```

The first one that matches is executed, and the result of the corresponding block (its last expression) is the result of the entire case expression. ***If no clause matches, an error is raised***

```elixir
def max(a,b) do
    case a >= do
        true -> a
        false -> b
    end
end
```

The case construct is most suitable if you don’t want to define a separate multiclause function.

### 3.3.3 The with special form

*with* can be very useful when you need to ***chain a couple of expressions*** and ***return the error of the first expression that fails.***

```elixir
${
"login" => "alice"
"email" => "some_mail"
"password" => "password"
"other_field" => "some_value"
"yet_another_field" => "..."
...
}
# result
%{login: "alice", email: "some_email", password: "password"}
```

```elixir
#without 'with' clause
def extract_user(user) do case extract_login(user) do
	{:error, reason} -> {:error, reason} {:ok, login} ->
		case extract_email(user) do
			{:error, reason} -> {:error, reason} {:ok, email} ->
				case extract_password(user) do {:error, reason} -> {:error, reason}
					{:ok, password} -> %{login: login, email: email, password: password}
			end
		end
	end
end
```

```elixir
#'with'
with pattern_1 <- expression_1,
	pattern_2 <- expression_2,
	...
do
...
end
```

```elixir
#with 'with' clause
iex(1)> witht {:ok, login} <- {:ok, "alice"},
	{:ok, email} <- {:ok, "some_email"} do
	%{login: login, email: email}
	end
```

## 3.4 Loops and Iterations

Looping in Elixir works very differently than it does in mainstream languages.

***The principal looping tool in Elixir is recursion***

### 3.4.1 Iterating with recursion

### 3.4.2 Tail function calls

Elixir (or, more precisely, Erlang) treats tail calls in a specific manner by performing a tail-call optimization. the tail function call consumes no additional memory

Tail calls are especially useful in recursive functions. ***A tail-recursive function can run virtually forever without consuming additional memory.***

```elixir
defmodule ListHelper do
  def sum(list) do
      do_sum(0, list)
  end

  defp do_sum(current_sum, [])  do
    current_sum
  end

  defp do_sum(current_sum, [head | tail]) do
    new_sum = head + current_sum
    do_sum(new_sum, tail)
  end
end

#iex run sum_list_tc.ex
#ListHelper.sum([1, 2, 3, 4, 5])
#15
```

#### Tail vs Non-Tail

Non-tail recursion often looks more elegant and concise, and it can in some circumstances yield better performance. When you write recursion, you should choose the solution that seems like a better fit

***If you need to run an infinite loop, tail recursion is the only way that will work.*** Otherwise, the choice amounts to which looks like a more elegant and performant solution.

#### Recognizing Tail Calls

Tail calls can take different shapes. ***A tail call can also happen in a conditional expression***

```elixir
def fun(...) do
	...
	if something do
		...
		another_fun(...)
	end
end
```

***But the following code isn't a tail call:***

```elixir
def fun(...) do
	# Not a tail call!!
	1 +  another_fun(...)
end
```

This is because the call to another_fun isn't the last thing done in the fun function.

> 꼬리제귀를 할 때에는 돌아올 위치를 기억 할 필요가 없기 때문에 스택에 추가적인 메모리가 필요없음

### 3.4.3 Higher-order functions

