using Statistics
abstract type AbstractTransform end
import Base.reverse

struct Transform{T<:AbstractTransform}
    meta::Dict{Symbol, Any}
    Transform{T}() where {T<:AbstractTransform} = new(Dict{Symbol, Any}())
end

const ABSTRACT_TRANSFORM_ERROR_STRING = "Type of Transform is not an specif inheritance of AbstractTransform"
fit(transform::Transform{<:AbstractTransform}, x) = error(ABSTRACT_TRANSFORM_ERROR_STRING)
apply(transform::Transform{<:AbstractTransform}, x) = error(ABSTRACT_TRANSFORM_ERROR_STRING)
reverse(transform::Transform{<:AbstractTransform}, x) = error(ABSTRACT_TRANSFORM_ERROR_STRING)
fit_apply(transform::Transform{<:AbstractTransform}, x) = (fit(transform, x); apply(transform, x))



struct IdTransform <: AbstractTransform end
idtransform() = Transform{IdTransform}()
fit(transform::Transform{IdTransform}, x) = nothing 
apply(transform::Transform{IdTransform}, x) = x
reverse(transform::Transform{IdTransform}, x) = x


struct NormTransform <: AbstractTransform end
normtransform() = Transform{NormTransform}()
function fit(transform::Transform{NormTransform}, x)
    transform.meta[:means]  = mean(x, dims=1)
    transform.meta[:stds]  = std(x, dims=1)
end
apply(transform::Transform{NormTransform}, x) = (x .- transform.meta[:means])./ transform.meta[:stds]
reverse(transform::Transform{NormTransform}, x) = (x .* transform.meta[:stds]) .+ transform.meta[:means]