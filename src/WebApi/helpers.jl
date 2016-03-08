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

function takefield(t::Any, )

function deserialize{T}(json_string::AbstractString)
    t = T()
    json = JSON.parse(json_string)
    for sym in fieldnames(T)
        println("Symbol: $(sym)")
        key = string(sym)
        takefield(json, t, sym)
    end
    t
end
