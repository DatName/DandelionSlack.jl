using JSON

deserialize{T}(::Type{T}, json::AbstractString) = deserialize(T, JSON.parse(json))
deserialize{T}(::Type{T}, json::Dict) =
    T(flatten([deserialize(T, f, json) for f in fieldnames(T)])...)
deserialize{T<:Integer}(::Type{T}, i::Integer) = T(i)
deserialize{T<:Integer}(::Type{T}, i::AbstractString) = parse(T, i)
deserialize{T<:AbstractFloat}(::Type{T}, i::AbstractFloat) = T(i)
deserialize{T<:AbstractFloat}(::Type{T}, i::AbstractString) = parse(T, i)
deserialize{T<:AbstractString}(::Type{T}, i::AbstractString) = T(i)
deserialize{T}(::Type{Nullable{T}}, json::AbstractString) = deserialize(T, json)
deserialize{T}(::Type{Nullable{T}}, json::Dict) = deserialize(T, json)
deserialize{T}(::Type{Nullable{T}}, x) = deserialize(T, x)

deserialize{Tf}(::Type{Tf}, field::AbstractString, json::Dict) = deserialize(Tf, json[field])
deserialize{Tf<:Nullable}(::Type{Tf}, field::AbstractString, json::Dict) =
    haskey(json, field) ? deserialize(Tf, json[field]) : Tf()
deserialize{T}(::Type{T}, field::Symbol, json::Dict) =
    deserialize(fieldtype(T,field), string(field), json)

flatten{T<:Array}(A::Array{T,1}) = vcat(flatten(A)...)
flatten{T}(A::Array{T,1}) = vcat(A...)
flatten(A) = A

