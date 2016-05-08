using JSON

export deserialize

# Deserialize a JSON string to a given type.
#
# Example:
# ```
# using Base.Test
#
# type Foo
#    bar::UTF8String
# end
#
# @test DandelionSlack.deserialize(Foo, """{"bar": "baz"}""") == Foo("baz")
# ```
#
# Nullable fields are considered optional, but all other fields are mandatory.
#
DandelionSlack.deserialize{T}(::Type{T}, json::AbstractString) = DandelionSlack.deserialize(T, JSON.parse(json))
DandelionSlack.deserialize{T}(::Type{T}, json::Dict) =
    T([deserialize_field(T, f, json) for f in fieldnames(T)]...)
function DandelionSlack.deserialize{T}(::Type{Array{T,1}}, a::Array{Any,1})
    result = Array{T, 1}()
    for e in a
        element_value = DandelionSlack.deserialize(T, e)
        push!(result, element_value)
    end
    result
end
DandelionSlack.deserialize{T<:Integer}(::Type{T}, i::Integer) = T(i)
DandelionSlack.deserialize{T<:Integer}(::Type{T}, i::AbstractString) = parse(T, i)
DandelionSlack.deserialize{T<:AbstractFloat}(::Type{T}, i::AbstractFloat) = T(i)
DandelionSlack.deserialize{T<:AbstractFloat}(::Type{T}, i::AbstractString) = parse(T, i)
DandelionSlack.deserialize{T<:AbstractString}(::Type{T}, i::AbstractString) = T(i)
DandelionSlack.deserialize{T}(::Type{Nullable{T}}, json::AbstractString) = DandelionSlack.deserialize(T, json)
DandelionSlack.deserialize{T}(::Type{Nullable{T}}, json::Dict) = DandelionSlack.deserialize(T, json)
DandelionSlack.deserialize{T}(::Type{Nullable{T}}, ::Void) = Nullable{T}()
DandelionSlack.deserialize{T}(::Type{Nullable{T}}, x) = DandelionSlack.deserialize(T, x)

# Deserialize a given field (name or symbol) from a Dict, into a given type.
deserialize_field{Tf}(::Type{Tf}, field::AbstractString, json::Dict) = DandelionSlack.deserialize(Tf, json[field])
deserialize_field{Tf<:Nullable}(::Type{Tf}, field::AbstractString, json::Dict) =
    haskey(json, field) ? DandelionSlack.deserialize(Tf, json[field]) : Tf()
deserialize_field{Tf}(ta::Type{Array{Tf}}, field::AbstractString, json::Dict) =
    DandelionSlack.deserialize(ta, json[field])

deserialize_field{T}(::Type{T}, field::Symbol, json::Dict) =
    deserialize_field(fieldtype(T,field), string(field), json)

flatten{T<:Array}(A::Array{T,1}) = vcat(flatten(A)...)
flatten{T}(A::Array{T,1}) = vcat(A...)
flatten(A) = A

