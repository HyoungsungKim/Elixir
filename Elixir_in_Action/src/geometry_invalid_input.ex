defmodule Geometry_invalid_input do
    def area({:rectangle, a, b}) do
        a * b
    end
    
    def area({:square, a}) do
        a * a
    end

    def are({:circle, r}) do
        r * r * 3.14
    end

    def area(unknown) do
        {:error, {:unknown_shape, unknown}}
    end
end