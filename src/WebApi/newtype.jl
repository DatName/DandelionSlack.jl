export @newtype
export @newimmutable

function fieldtype_from_type_expr(typedef)
    new_typeexpr = typedef.args[1]
    if isa(new_typeexpr, Symbol)
        # First argument is a symbol, like Foo in "@newtype Foo <: AbstractsString". That means it's
        # not a generic expression. In that case we default to using the supertype (here
        # AbstractString) as field type.
        field_type = typedef.args[3]
    else
        # First argument is an expression, like Foo{T} in "@newtype Foo{T} <: AbstractString". That
        # means it's a generic expression, so we use the T in Foo{T} or Foo{T <: AbstractString} as
        # the field type.
        if isa(new_typeexpr.args[2], Symbol)
            field_type = new_typeexpr.args[2]
        else
            field_type = new_typeexpr.args[2].args[1]
        end
    end
    field_type
end

macro newtype(typedef)
    field_type = fieldtype_from_type_expr(typedef)

    tname = typedef.args[1]
    sname = typedef.args[3]

    quote
        type $tname <: $sname
            v::$(field_type)
        end
    end
end

macro newimmutable(typedef)
    field_type = fieldtype_from_type_expr(typedef)

    tname = typedef.args[1]
    sname = typedef.args[3]

    quote
        immutable $tname <: $sname
            v::$(field_type)
        end
    end
end

macro stringinterface(typesym)
    quote
        Base.endof(x::$typesym) = Base.endof(x.v)
        Base.next(x::$typesym, i::Int) = Base.next(x.v, i)
    end
end
