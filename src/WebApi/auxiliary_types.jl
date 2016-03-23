export Id
export Name

export endof

for sym in [:Id, :Name]
    @eval begin
        immutable ($sym) <: AbstractString
            v::AbstractString
        end

        Base.endof(a::($sym)) = Base.endof(a.v)
        Base.next(a::($sym), x::Int) = Base.next(a.v, x)
    end
end

