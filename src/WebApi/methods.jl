export Status
export SlackMethod
export AbstractHttp
export RequestException

import Base.==

abstract AbstractHttp

immutable Status
    ok::Bool
    error::Nullable{UTF8String}
    warnings::Nullable{UTF8String}
end

function nulleq{T}(a::Nullable{T}, b::Nullable{T})
    !isnull(a) && !isnull(b) && get(a) == get(b) || isnull(a) && isnull(b)
end

function ==(a::Status, b::Status)
    nulleq(a.error, b.error) && nulleq(a.warnings, b.warnings) && a.ok == b.ok
end

type RequestException <: Exception end
type HttpException <: Exception end

function makerequest(m::Any, http::AbstractHttp)
    query_vars = toquery(m)
    name = method_name(typeof(m))
    url = "https://slack.com/api/$(name)"
    resp = post(http, url; query=query_vars)
    if resp.code != 200
        throw(HttpException())
    end
    status = deserialize(Status, resp.body)
    if !status.ok
        throw(RequestException())
    end
    response_type = getresponsetype(typeof(m))

    status, deserialize(response_type, resp.body)
end
