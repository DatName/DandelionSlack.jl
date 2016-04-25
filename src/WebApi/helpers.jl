import JSON

export
    toquery,
    @slackmethod,
    getresponsetype,
    method_name

isset(t::Any) = true
isset{T}(t::Nullable{T}) = !isnull(t)

getfieldvalue(t::Any) = t
getfieldvalue{T}(t::Nullable{T}) = get(t)

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

macro slackmethod(req_type::Symbol, method_name::AbstractString, req_block::Expr, resp_block::Expr)
    local resp_type = Symbol(string(req_type) * "Response")

    quote
        immutable $req_type
            token::Token
            $(req_block.args...)
        end

        immutable $resp_type
            $(resp_block.args...)
        end

        $(esc(:getresponsetype))(::Type{$(esc(req_type))}) = $(esc(resp_type))
        $(esc(:method_name))(::Type{$(esc(req_type))}) = $method_name
    end
end

