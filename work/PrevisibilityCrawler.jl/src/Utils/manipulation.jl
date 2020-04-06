using DataFrames

# Flat a array to one dimension
flat(x) = collect(Iterators.flatten(x))

# Extract the values from a Julia dataframe row as a vector
vector(x) = vec(permutedims(Vector(x)))

# Convert a dataframe to an Array
value(x::DataFrame) = convert(Matrix, x)

# Convert a column dataframe to a flat Array with one Dimension
value1d(x::DataFrame) = flat(convert(Matrix, x))

# Normalize Dataframe to have unit variance colwise
normalize(x::DataFrame) = DataFrame(colwise(x -> x/std(x), x))


# Return index of element closest to value in vector
function get_closest_index(vector, value)
    diffs = vector .- value
    try
        findall(x -> x==min(abs.(diffs)...), abs.(diffs))[1]
    catch
        println(vector)
        throw("Error getting closest index")
    end
end