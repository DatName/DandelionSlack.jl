import JSON

export toquery

function isset(t::Any)
    true
end

function isset{T}(t::Nullable{T})
    !isnull(t)
end

function getfieldvalue(t::Any)
    t
end

function getfieldvalue{T}(t::Nullable{T})
    get(t)
end

function toquery{T}(t::T)
    query_vars = Dict()
    for name in fieldnames(T)
        field = getfield(t, name)
        if isset(field)
            v = getfieldvalue(field)
            query_vars[string(name)] = v
        end
    end
    query_vars
end

# Questions:
# 1. How are exceptions made and thrown?
# 2. What is haskey called for Dict?
# 3. Can I do Nullable{fieldtype} for a datatype in a variable?
# 4. I might need to convert the value before returning, how? convert function?

type MandatoryFieldNotPresentException <: Exception end

# Take a value from a Dict, given a symbol and a datatype, and return it.
# Raises an exception if the field is required and not present in the Dict.
function takefield(datatype::DataType, sym::Symbol, json::Dict)
    membertype = fieldtype(datatype, sym)
    fname = string(sym)
    println("fname $(fname), sym $(sym), json $(json)")
    if membertype <: Nullable
        if haskey(json, fname)
            return membertype(json[fname])
        end
        return membertype()
    else
        if !haskey(json, fname)
            throw(MandatoryFieldNotPresentException())
        end
        return json[fname]
    end
end

# Deserialize a JSON string into a object of type T.
# 
# `T` is the type you want to deserialize into.
# `json_string` is the JSON string.
function deserialize{T}(datatype::T, json_string::AbstractString)
    v = []
    json = JSON.parse(json_string)
    println("Sybols: $(fieldnames(T))")
    for sym in fieldnames(datatype)
        println("Symbol: $(sym)")
        key = string(sym)
        value_from_json = takefield(datatype, sym, json)
        push!(v, value_from_json)
    end
    println("Values: $(v)")
    datatype(v...)
end
