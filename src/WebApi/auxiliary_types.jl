import Base.endof
import Base.next

export Id
export Name

export endof

immutable Id <: AbstractString
    v::AbstractString
end

function endof(a::Id)
    endof(a.v)
end

function next(a::Id, x::Int)
    next(a.v, x)
end

immutable Name <: AbstractString
    v::AbstractString
end

function endof(a::Name)
    endof(a.v)
end

function next(a::Name, x::Int)
    next(a.v, x)
end
