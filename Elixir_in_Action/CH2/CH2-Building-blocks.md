# CH 2 Building blocks

This chapter covers

- Using the interactive shell
- Working with variables
- Organizing your code
- Understanding the type system
- Working with Operators
- Understanding the runtime



##  Working with variables

Elixir is a dynamic programming language -> It doesn't explicitly declare a variable or its type. Instead, the variable is determined by whatever data it contains at the moment. In Elixir terms, assignment is called *binding*. 

```elixir
monthly_salary = 10000
```

In Elixir, a variable name always starts with a lowercase alphabetic -> In Erlang Variable start with uppercase

```Erlang
#Erlang
A = 100.

#Elixir
a = 100
```



Also variable name can be end with the question mark or exclamation mark characters.  

Variable names can be rebound to a different value.

```elixir
#Erlang
A = 100.
A = 110.
#Error

#Elixir
a = 100
a = 110
#Possible

```

Elixir is a ***garbage-collection language.***  



## 2.3 Organizing your code

### 2.3.1 Modules

A modules is a collection of functions, somewhat like a namespace. Every Elixir function must be defined inside a module.

A module name must follow certain rules. It starts with an uppercase letter and is usually written in CamelCase style.



### 2.3.2 Functions ###

 As with variable, function names can end with the ? and ! characters. The ? character is often used to indicate a function that returns either true or false. Placing the character ! at the end of the name indicates a function that may raise a runtime error.-> Both of these are conventions, rather than rules.

 Function can be defined using the def macro

```elixir
defmodule Geometry do
    def rectangle_area(a, b) do
    ...
	end
	
	def function_has_no_argument do
	...
	end
end	
```

 There is no explicit return in Elixir -> The return value of a function is the return value of its last expression.

```elixir
Geometry.rectangle(3,2)
Geometry.rectangle 3, 2

#Same expression
```

Elixir comes with a built-in operator, |>, called *pipeline operator*

```elixir
-5 |> abs() |> (Integer.to-string(abs(-5)))
```

Pipeline operator places the result of the previous call as the first argument of the next call. So the following code,

```elixir
prev(arg1, arg2) |> next(arg3, arg4)
#It means
next(prev(arg1, arg2), arg3, arg4)
```

***Multi-line pipelines don;t work in the shell***



### 2.3.3 Function arity ###

Arity is a fancy name of the number of arguments a function receives.

```elixir
defmodule Rectangle do
	def area(a), do: area(a,a)  %%Rectangle.area/1 -> 1 arity
	def area(a, b) do: a * b	%%Rectangle.area/2 -> 2 arity
```



```elixir
# Same-name functions, different arities, default params
defmodule Calculator do
    def sum(a) do
    	sum(a, 0)
    end
    
    def sum(a, b) do  
	    a + b
    end
end
```

A lower-arity function is implemented in terms of a higher-arity one, This pattern is so frequent that Elixir allows you to specify defaults for arguments by using the \ ***\\operaor*** followed by the ***argument's*** default value

```elixir
defmodule Clculator do
	def sum(a, b \\ 0) do
		a + b
	end
end
```

```elixir
defmodule MyModule do
	def fun(a, b \\ 1, c, d, \\ 2) do
		a + b + c + d
	end
end
```

>  Similar with argument of fun in C/C++ or other language
>
> But in Elixir, \\\ set default of ***multiple argument***



### 2.3.4 Function visibility ###

- def  : public function -> can be called by anyone else
- defp : A private function can be used inly inside the module it is defined in.    

```elixir
# Module with a public and a private function
defmodule TestPrivate do
    def double(a) do 		# Public function
        sum(a,b) 		# Calls the private function
    end

    defp sum(a,b) do		# Private function
        a + b
        end
    end    
```



### 2.3.5 Imports and aliases

Calling functions from another module can sometimes be cumbersome because it needs to reference the module name. Importing a module allows to call its public functions without prefixing them.



```elixir
defmodule MyModule do
	import IO
	
	def my_function do
		puts "Calling imported function"
		#IO:puts "Calling imported function"
	end
end
```



Of course, multiple modules can be imported. In fact, the standard library's *kernel* module is automatically imported into every module.

Another construct, *alias*, makes it possible to reference a module under a different name.

```elixir
def MyModule do
    alias IO, as MyIO
    
    def my_function do
    	MYIO.puts("calling imported function")
    end
end

```

```elixir
defmodule MyModule do
	alias Geometry.Rectangle, as: Rectangle
	
	def my_function do
		Rectangle.area(...)
	end
end
```



### 2.3.6 Module attribute

The purpose of module attribute is twofold: they can be used as compile-time constant, and you can register any attribute, which can then be queried in runtime.



```elixir
defmodule Circle do
	@pi 3.14156
	
	def area(r), do: r*r*@pi
	def circumference(r), do: 2*r*@pi
end
```

This is permitted and makes it possible to experiment without storing any files on disk.

The important thing about the @pi constant is that it exists only during the compilation of the module, when the references to it are inlined.



Moreover, attribute can be registered, which means it will be stored in the generated binary and can be accessed at runtime. Elixir registers some module attributes by default.

-> @moduledoc @doc can be used to provide documentation for modules and finctions



```elixir
defmodule Circle do
	@moduledoc "Implements basic circle functions"
	@pi 3.14159
	
	@doc "Computes the area of a circle"
	def area(r), do:r*r*@pi
	
	@doc Computes "the circoumference of a circle"
	def circumference(r), do: 2*r*r*@pi
end

#output
#iex(1)> Code.get_docs(Circle, :moduledoc)
#{1, "Implements basic circle functions"}

#output with help feature
#help feature is h
#iex(2)> h Circle			-> Circle
#Implements basic circle functions
#iex(3)> h Circle.area		-> def area(a)
#Computes the area of a circle

```



### Type specifications

Type specifications (often called *typespecs*) are another important feature based on attributes.

This feature allows you to provide type information for your functions, which can later be analyzed with a static analysis tool called dialyzer

```elixir
defmoducle Circle do
    @pi 3.14159
    @spec area(number) :: number			#Type specification for area/1
    def area(r), do : r*r*@pi
    
    @spec circumference(number) :: number
    def circumference(r), do: 2*r*@pi	#Type specification for circumference/1
end
```

*@spec* attribute to indicate that both functions accept and return a number

remember that Elixir is a dynamic language, so function inputs and output cannot be easily deduced by looking at the function's signature.  Typespecs can help significantly with this, and i can personally attest that it's much easier to understand someone else's code when typespces are provided.

```elixir
#example of typespecs
List.insert_at/3:
@spec insert_at(list, integer, any) :: list
```

> In this book, Writer will not use typespecs but i have to practice by myself for a complex structure which i will implement.
>
> ... Really can i implement? T_T



## 2.4 Understanding the type system

As its core, Elixir uses the Erlang type system. Consequently, integration with Erlang libraries is usually simple. 

### 2.4.1 Numbers

Numbers can be integers or floats, and they work mostly as you'd expect

```elixir
integer : 3
integer written in hex : 0xFF -> 255
float : 3.14
float, exponential notation : 1.0e-2 -> 0.01

div(5,2) = 2
rem(5,2) = 1 -> modular arithmetic

//There is no limit on an integer's size
99999999999999999999999999999999999999999999999999999999
```

***About memory***

- An integer takes up as much space as needed to accommodate the number
- Float occupies either 32 or 64 bits, depending on the build architecture of the virtual machine



### 2.4.2 Atoms

Atoms are literal names constants. ***They're similar to symbols in Ruby or enumeration in C/C++.*** Atom constants start with a colon character, followed by a combination of alphanumerics and/or underscore character.

```elixir
:an_atom
:another_atom
//It is possible to use space in the atom name with the following syntax
:"an atom with space"
```

An atom consists of two parts: ***the text and the value.*** The atom text is whatever you put after the colon character. At runtime, ***this text is kept in the atom table. The value is the data that goes into the variable, and it is merely a reference to the atom table*** 

> -> similar with enum in C/C++

```elixir
variable = :some_atom
```

- Variable doesn't contain the entire text, but only a reference to the atom table.

  ***->  Therefore memory consumption is low, the comparisons are fast and the code is still readable***

#### Aliases

There is another syntax for atom constant. ***You can omit the beginning colon and start with an uppercase character.***

```elixir
AnAtom
#At compile time, it is transformed into this
:"Elixir.AnAtom":
iex(1) > AnAtom == :"Elixir.AnAtom"
true
```

- ***When programmer use am alias, the compiler implicitly adds the Elixir.***
- But if an alias already contains that prefix, It is not added.

```elixir
iex(2) > AnAtom == Elixir.AnAtom
true
```

- Also alias can be used to gibe alternate names to modules

```elixir
iex(3) > alias IO, as: MyIO
iex(4) > MyIO.puts("Hello!")
Hello!
#-> the term alias is used for both things.
iex(5) > MyIO == Elixir.IO
true
```

#### Atoms AS Booleans

***Elixir doesn't have a dedicated Boolean type*** Instead, the atoms :true and :false are used As syntactic sugar.

```elixir
iex(1) > :true == true
true
iex(2) > :false == false
true
```

- ***Always keep in mind that a Boolean is just an atom that has a value of true or false.***

#### Nil and Truthy values

Another special atom is :nil, which works ***somewhat similarly to null from other languages.***

- Can reference nil without a colon

```elixir
iex(1) > nil == : nil
true
```



The atom nil plays a role in Elixir’s additional support for truthfulness. ***The atoms nil and false are treated as falsy values, whereas everything else is treated as a truthy value.***

```elixir
iex(1) > nil || false || 5 || true
5
iex(2)> true && 5
5
iex(3)> false && 5
false
iex(4)> nil && 5
nil
```

Because both nil and false are falsy expressions, the number 5 is returned.

> Similarly with C/C++
>
> ```c++
> int main(){
>     if(a && b){
>         //if a is false then don't check b
>     }
>     
>     if(a || b){
>         //if a is true don't check b
>     }
> }
> ```

Short-circuiting can be used for elegant operation chaining. For example, if you need to fetch a value from cache, a local disk, or a remote database, you can do something like this

```elixir
read_cached || read_from_disk || read_from_database
#A first data that is treated as true is returned 
database_value = connection_established? && read_data
#if connection_established? is not ture then don't need to check read_data
```

In both examples, short-circuit operators make it possible to write concise code without resorting to complicated nested conditional constructs.

### 2.4.3 Tuples

Tuples are something like untyped structures, or records, and they're most often used to group a fixed number or elements together.

```elixir
person = {"Bob", 25}
age = elem(person, 1) #age is 25
put_elem(person,1 ,26) #{"Bob", 26}
```

***The function put_elem doesn't modify the tuple. It returns the new version, keeping the old one intact.***

- Recall that data in ***Elixir is immutable***, so you can’t do an in-memory modification of a value.

> Elixir is immutable but it looks mutable(can overwrite: exactly overwrite-like)

```elixir
iex(1)> person
{"Bob", 25}	#person is not changed

older_person = put_elem(person, 1, 26)
#older_person is {"Bob", 26}
iex(2)> person = put_elem(person, 1, 26)
iex(3)> person
{"Bob", 26}
#Variable rebound to the new memory location
#The old location is not referenced by any other variable, so it is eligible for garbage
#-> delete last one and allocate again(overwrite-like)
```



### 2.4.4 Lists

Lists in Erlang are used to manage dynamic, variable-sized collections of data, The syntax deceptively resembles arrays form other languages.

```elixir
iex(1)> prime_numbers =[2, 3, 5, 7]
iex(2)> Enum.at(prime_numbers, 3) # return 7
```

Lists may look like arrays, but they work like singly linked lists. To do something with the list, you have to traverse it.

> indexing list is O(N) So it is later than array. But list is easier to put data then array



```elixir
#"in" operator
iex(3)> 5 in prime_numbers # return false
iex(4)> List.replace_at(prime_numbers, 0, 11)
[11, 3, 5, 7]
#prime_numbers is still [2, 3, 5, 7]
iex(5)> new_primes = List.replace_at(prime_numbers, 0, 11)
or
iex(5)> prime_numbers = List.replace_at(prime_numbers, 0, 11)
```

insert a new element at the specified position with the *List.insert_at*

```elixir
iex(6)> List.insert_at(prime_numbers, 3, 13)
[11, 3, 5, 13, 7]
```

***To append to the end, you can use a negative value for the insert position***

```go
iex(7)> List.insert_at(prime_numbers, -1, 13)
[11, 3, 5, 7, 13]
iex(8)> [1, 2, 3] ++ [4, 5]
[1, 2, 3, 4, 5]
```

In general, ***you should avoid adding elements to the end of a list.*** Lists are most efficient when new elements are pushed to the top, or popped from it. To understand why, let’s look at the recursive nature of lists.

#### Recursive List Definition

In elixir, There is a special syntax to support recursive list definition

```elixir
a_list [head|tail]
```

- ***head can be any type of data,***
- whereas ***tail is itself a list***. If *tail* is an empty list, it indicates the end of the entire list.

```elixir
iex(1)> [1 | []]
[1]
iex(2)> [1 | [2 | []]]
[1, 2]
iex(3)> [1 | [2]]
[1, 2]
iex(4)> [1 | [2, 3, 4]]
[1, 2, 3, 4]
#Canonical recursive
iex(5)> [1 | [2 | [3 | [4 | []]]]]
[1, 2, 3, 4]
```

Of course, nobody wants to write constructs like this one. ***But it’s important that you’re always aware that, internally, lists are recursive structures of (head, tail ) pairs.***

To get the head of the list, you can use the hd function. The tail can be obtained by calling the tl function:

```elixir
iex(1)> hd([1, 2, 3, 4])
1
iex(2)> tl([1, 2, 3, 4])
[2, 3, 4]
iex(3)> a = [1]
iex(4)> tl(a)
[]
iex(5)> tl(a)
1	#Not a list but data
```

Both operations are O(1), because they amount to reading one or the other value from the (head, tail ) pair.

***Construction of the new_list is an O(1) operation***

### 2.4.5 immutability

As has been mentioned before, Elixir data cannot be mutated, ***Every function returns the new, modified version of the input data.*** You have to take the new version into another variable or rebind it to the same symbolic name. In any case, the result resides in another memory location. ***The modification of the input will result in some data copying,*** but generally, ***most of the memory will be shared between the old and the new version.***

#### Modifying Tuples

A modified tuple is always a complete, ***shallow copy of the old version.*** 

```elixir
a_tuple = {a, b, c}
new_tuple = put_elem(a_tuple, 1, b2)
```

The variable *new_tuple* will contain a shallow copy of *a_tuple)

>  New element *b2* is added in memory and ***new_tuple shares same a and c  with a_tuple*** and reference *b2*

***What happens if you rebind a variable?***
In this case, after rebinding, the variable *a_tuple* references another memory location. ***The old location of a_tuple is not accessible and is available for garbage collection***

***Keep in mind that tuples are always copied, but the copying is shallow. Lists, however, have different properties.***

#### Modifying lists

*When you modify the nth element of a list*, the new version will contain ***shallow copies of the first n-1 elements,*** followed by the modified element. ***After that, the tails are completely shared.***

> shallow copy from begin to n -1 index, and share last elements

This is precisely why adding elements to the end of a list is *expensive*. To append a new element at the tail, you have to iterate and (shallow) copy the entire list.

In contrast, ***pushing an element to the top of a list doesn't copy anything which makes it the least expensive operation.***

#### Benefits

Immutability may seem strange, and you may wonder about its purpose. There are two important benefits of immutability

- Side-effect-free functions
- Data consistency.

Given that data can’t be mutated, you can treat most functions as side-effect-free transformations. They take an input and return a result. More complicated programs are written by combining simpler transformations:

```elixir
#pipe operator : pass a result to the next function as first argument
def complex_transformation(data) do
    data
    |> transformation_1(..)
    |> transformation_2(..)
    |> transformation_3(..)
    ....
    |> transformation_n(..)
end
```

This code relies on the previously mentioned pipeline operator that chains two functions together, feeding the result of the previous call as the first argument of the next call.

***Elixir is not a pure functional language, so functions may still have side effects.*** For example, a function may write something to a file and issue a database or network call, which cause it to produce a side-effect

-> But you can be certain that a function will not modify the value of any variable.

```elixir
def complex_transformation(original_data) do
    original_data
    |> transformation_1(...)
    |> transformation_2(...)
    ...
end
```

***If something goes wrong, the function complex_transformation can return original_data,*** which will effectively roll back all of the transformations performed in the function. ***This is possible because none of the transformations modifies the memory occupied by original_data***

### 2.4.6 Maps

A map is a key/value store, where keys and values can be any term. ***maps have dual usage in Elixir.***

- They are used to power ***dynamically sized key/value structures***
- But they are also used to manage ***simple records-a couple of well-defined names fields bundled together.***

#### Dynamically sized maps

An empty map can be created with the %{} construct:

```elixir
iex(1)> empty_map = %{}
```

A map with some values can be created with the following syntax:

```elixir
iex(2)> squares = %{1 => 1, 2=> 4, 3=> 9}
```

you can also prepolulate a map with the *Map.new/1* function. The function takes an enumerable where each elements is a tuple of size two (a pair)

> populate : 거주하다

```elixir
iex(3)> squares = Map.new([{1,1}, {2,4}, {3,9}])
%{1 => 1, 2 => 4, 3 => 9}
##function(list[atom{}])
iex(4)>squares[2]
4
iex(5)>squares[4]
nil
```

In the second expression, you get a *nil* because no value is associated with the given key.

A similar result can be obtained with *Map.get/3*.  ***But Map.get/3 allows you to specify the default value.***, which is returned if the key is not found. ***If this default is not provided, nil will be returned.***

```elixir
iex(6)> Map.get(squares, 2)
4
iex(7)> Map.get(squares, 4)
nil
iex(8) Map.get(squares, 4, :not_found)
:not_found
#":not_found" is used as default value
```

If you want to precisely distinguish between there cases, you can use *Map.fetch/2*

```elixir
iex(9)> Map.fetch(squares, 2)
{:ok, 4}
iex(10)> Map.fetch(squares, 4)
:error
```

> fetch : (어디를 가서) 가지고 오다, (특정 가격에) 팔리다
>
> patch : 패치, (구멍 난데를 때우는)조각

Sometimes you want to proceed only if the key is in the map, and raise an exception otherwise. This can be done with the *Map.fetch!/2* function.

```elixir
iex(11)> Map.fetch!(squares, 2)
4
iex(12)> Map.fetch!(squares, 4)
** (KeyError) ~
```

To store new element to the map, Map.put/3

```elixir
iex(13)> squares = Map.put(squares, 4, 16)
%{1 => 1, 2=> 4, 3=> 9, 4=> 16}
iex(14)> squares[4]
16
```

For more [information](https://hexdocs.pm/elixir/Map.html)

***A map is also enumerable, which means that all the functions from the Enum module can work with maps.***

#### Structured Data

Maps are the go-to type for managing key/value data structures of an arbitrary size. ***But they're also frequently used in Elixir to combine a couple of fields into a single structure.***

This use case somewhat overlaps that of tuples, but it provides the advantage of allowing you to access field by name.

```elixir
#key => variable
iex(1)>bob = %{:name => "Bob", :age => 25, :work_at => "Initech"}
#if Keys are atom you can write this(same)
iex(2)>bob = %{name: "Bob", age: 25, work_at: "Initech"}
```

To retrive a field, you can use the []operator

> Atom constants start with a colon character, followed by a combination of alphanumerics and/or underscore character.
>
> Ex) :hello, :"atom is here", :blockchain
>
> retrieve : 검색하다.

```elixir
iex(3)>bob[:works_at]
"Initech"
iex(4)bob[:non_existent_field]
nil
```

Atom keys again receive special syntax treatment

```elixir
iex(5)> bob.age
25
iex(6)bob.non_existent_field
** (KeyError) key :~
```

To change a field value, 

```elixir
#Original data : %{name: "Bob", age: 25, work_at: "Initech"}
iex(7)> next_years_bob = %{bob | age:26}
%{name: "Bob", age: 26, work_at: "Initech"}
#Multiple attributes as well
iex(8) %{bob | age:26, works_at: "initrode"}
%{name: "Bob", age: 26, work_at: "initrode"}
```

***But you can only modify values that already exist in the map.*** If you mistype the field name, you will get an immediate runtime error:

```elixir
iex(9)> %{bob | works_in: "Initech"}
** (KeyError) ~
```

***Using maps to hold structured data is a frequent pattern in Elixir***  The common pattern is to provide all the fields while creating the map, using atoms as keys. If the value for some field is not available, you can set ti to nil. to fetch a desired field, you can use the *a_map.some_field*

also can use Map module, such as *Map.put/3* or *Map.feetch/2*  But ***This function is usually suitable for the case where maps are used to manage a dynamically sized key/value structure.***



