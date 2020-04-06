using Plots

struct Trig
    start_p::Union{Float64, Nothing}
    mid::Float64
    end_p::Union{Float64, Nothing}
end

function params(trig::Trig)
    [trig.start_p, trig.mid, trig.end_p]
end

function μ(value::Float64, trig::Trig)    
    if value <= trig.mid
        if trig.start_p == nothing
            return 1.
        elseif value <= trig.start_p
            return 0.
        else
            return (value - trig.start_p)/(trig.mid - trig.start_p)
        end
    else 
        if trig.end_p == nothing
            return 1.
        elseif value >= trig.end_p
            return 0.
        else
            return 1 - ((value - trig.mid)/(trig.end_p - trig.mid))
        end
    end
end

function even_range(start_p::Float64, end_p::Float64, nr_sets::Int64)
    nr = nr_sets - 2 
    interval = (end_p - start_p)/(nr + 1)
    sets = [Trig(start_p + (i-1)*interval, start_p + i*interval, start_p + (i+1)*interval) for i in 1:nr]
    pushfirst!(sets, Trig(nothing, sets[1].start_p, sets[1].mid))
    push!(sets, Trig(sets[end].mid, sets[end].end_p, nothing))
end 
        
@recipe function f(::Type{Trig}, set::Trig)
    x = [set.start_p == nothing ? set.mid - 1 : set.start_p, 
            set.mid, set.end_p == nothing ? set.mid + 1 : set.end_p]
    y = [set.start_p == nothing ? 1 : 0, 1, set.end_p == nothing ? 1 : 0]
    (y, x)
end
               
@recipe function f(sets::Array{Trig,1})
    x = [[set.start_p == nothing ? set.mid - 1 : set.start_p, 
            set.mid, set.end_p == nothing ? set.mid + 1 : set.end_p] for set in sets]
    y = [[set.start_p == nothing ? 1 : 0, 1, set.end_p == nothing ? 1 : 0] for set in sets]
    (x, y)
end