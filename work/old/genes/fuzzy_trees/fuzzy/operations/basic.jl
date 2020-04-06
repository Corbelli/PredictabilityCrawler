# Contains the avaiable operations, aggregated by arity
struct Operations
    arity_one::Array{Function,1}
    arity_two::Array{Function,1}
end

# avaiable operations
t_product(a::Float64, b::Float64) = a*b
t_min(a::Float64, b::Float64) = min(a, b)
t_luk(a::Float64, b::Float64) = max(0., a + b -1)
dilute(a::Float64) = sqrt(a)
concentrate(a::Float64) = a^2

#Declares the arities vectors and the currently avaiable operations
arity_one = [dilute, concentrate]
arity_two = [t_product, t_min, t_luk]
basic_operations = Operations(arity_one, arity_two)

