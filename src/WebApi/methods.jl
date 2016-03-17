export Status
export SlackMethod
export AbstractHttp
export RequestException

abstract SlackMethod
abstract AbstractHttp

immutable Status
    ok::Bool
    error::Nullable{AbstractString}
    warnings::Nullable{AbstractString}
end

type RequestException <: Exception end

function makerequest(m::SlackMethod, http::AbstractHttp)
    query_vars = toquery(m)
    name = method_name(typeof(m))
    url = "https://slack.com/api/$(name)"
    resp = post(http, url; query=query_vars)
    status = deserialize(Status, resp.body)
    if !status.ok
        throw(RequestException())
    end
    response_type = getresponsetype(typeof(m))


    status, deserialize(response_type, resp.body)
end
