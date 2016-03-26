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
# @test deserialize(Foo, """{"bar": "baz"}""") == Foo("baz")
# ```
#
# Nullable fields are considered optional, but all other fields are mandatory.
#
deserialize{T}(::Type{T}, json::AbstractString) = deserialize(T, JSON.parse(json))
deserialize{T}(::Type{T}, json::Dict) =
    T([deserialize_field(T, f, json) for f in fieldnames(T)]...)
function deserialize{T}(::Type{Array{T}}, a::Array{Any})
    result = Array{T, 1}()
    for e in a
        element_value = deserialize(T, e)
        push!(result, element_value)
    end
    result
end
deserialize{T<:Integer}(::Type{T}, i::Integer) = T(i)
deserialize{T<:Integer}(::Type{T}, i::AbstractString) = parse(T, i)
deserialize{T<:AbstractFloat}(::Type{T}, i::AbstractFloat) = T(i)
deserialize{T<:AbstractFloat}(::Type{T}, i::AbstractString) = parse(T, i)
deserialize{T<:AbstractString}(::Type{T}, i::AbstractString) = T(i)
deserialize{T}(::Type{Nullable{T}}, json::AbstractString) = deserialize(T, json)
deserialize{T}(::Type{Nullable{T}}, json::Dict) = deserialize(T, json)
deserialize{T}(::Type{Nullable{T}}, ::Void) = Nullable{T}()
deserialize{T}(::Type{Nullable{T}}, x) = deserialize(T, x)

# Deserialize a given field (name or symbol) from a Dict, into a given type.
deserialize_field{Tf}(::Type{Tf}, field::AbstractString, json::Dict) = deserialize(Tf, json[field])
deserialize_field{Tf<:Nullable}(::Type{Tf}, field::AbstractString, json::Dict) =
    haskey(json, field) ? deserialize(Tf, json[field]) : Tf()
deserialize_field{Tf}(ta::Type{Array{Tf}}, field::AbstractString, json::Dict) =
    deserialize(ta, json[field])

deserialize_field{T}(::Type{T}, field::Symbol, json::Dict) =
    deserialize_field(fieldtype(T,field), string(field), json)

flatten{T<:Array}(A::Array{T,1}) = vcat(flatten(A)...)
flatten{T}(A::Array{T,1}) = vcat(A...)
flatten(A) = A

