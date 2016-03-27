export
    @newtype,
    @newimmutable,
    @stringinterface

# Given a type definition Foo <: AbstractString, or Foo{T} <: AbstractString, return the inner
# type of the new composite type..
#
# Case 1: ```Foo <: AbstractString```
#         In this case the inner type is ```AbstractString```
#
# Case 2: ```Foo{T} <: AbstractString```
#         In this case the inner type is ```T```
#
# Case 3: ```Foo{T <: AbstractString}```
#         In this case the inner type is ```T```
function inner_type_from_type_expr(typedef)
    new_typeexpr = typedef.args[1]
    if isa(new_typeexpr, Symbol)
        # Case 1:
        # First argument is a symbol, like Foo in "@newtype Foo <: AbstractsString". That means it's
        # not a generic expression. In that case we default to using the supertype (here
        # AbstractString) as inner type.
        field_type = typedef.args[3]
    else
        # First argument is an expression, like Foo{T} in "@newtype Foo{T} <: AbstractString". That
        # means it's a generic expression, so we use the T in Foo{T} or Foo{T <: AbstractString} as
        # the inner type.
        if isa(new_typeexpr.args[2], Symbol)
            # Case 2:
            field_type = new_typeexpr.args[2]
        else
            # Case 3:
            field_type = new_typeexpr.args[2].args[1]
        end
    end
    field_type
end

# Determine the type of the inner nd the supertype, given the type definition provided to the
# macro.
#
# Returns: (inner type, super type)
#
# If the supertype in the type definition is an abstract type, then that is the supertype, and we
# figure out the inner type using ```inner_type_from_type_expr()```. So, for instance, if we have
# ```@newtype Foo <: AbstractString```, then the supertype is ```AbstractString```, and by the
# rules of ```inner_type_from_type_expr()``` the inner type will also be ```AbstractString```.
# However, if the supertype is a concrete type, then we cannot subclass it, since Julia doesn't
# allow that. In this case we interpret it to mean that we want the inner type to be that cóncrete
# type, and we'll use the same supertype as the super type of the concrete type.
# For instance, ```Foo <: UTF8String``` will create a new type:
# ```
# immutable Foo <: AbstractString
#   v::UTF8String
# end
# ```
# because ```UTF8String <: AbstractString```.
function determine_types(typedef)
    local sname = typedef.args[3]
    local supertype = eval(sname)
    if isleaftype(supertype)
        return sname, super(supertype)
    else
        return inner_type_from_type_expr(typedef), sname
    end
end

macro newtype(typedef)
    local tname = typedef.args[1]
    local mytypes = determine_types(typedef)
    local inner_type = mytypes[1]
    local sname = mytypes[2]
    quote
        type $tname <: $sname
            v::$(inner_type)
        end
    end
end

macro newimmutable(typedef)
    local tname = typedef.args[1]
    local mytypes = determine_types(typedef)
    local inner_type = mytypes[1]
    local sname = mytypes[2]
    quote
        immutable $tname <: $sname
            v::$(inner_type)
        end
    end
end

macro stringinterface(typesym)
    quote
        Base.endof(x::$(esc(typesym))) = Base.endof(x.v)
        Base.next(x::$(esc(typesym)), i::Int) = Base.next(x.v, i)
    end
end
