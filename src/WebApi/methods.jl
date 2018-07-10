export Status
export SlackMethod
export AbstractHttp
export AbstractHttpResponse
export RequestException
export makerequest

import Base.==

abstract type AbstractHttp end
abstract type AbstractHttpResponse end

statuscode(r::AbstractHttpResponse) = r.status
text(r::AbstractHttpResponse) = r.text

struct Status
    ok::Bool
    error::Nullable{String}
    warnings::Nullable{String}
end

function nulleq{T}(a::Nullable{T}, b::Nullable{T})
    !isnull(a) && !isnull(b) && get(a) == get(b) || isnull(a) && isnull(b)
end

function ==(a::Status, b::Status)
    nulleq(a.error, b.error) && nulleq(a.warnings, b.warnings) && a.ok == b.ok
end

mutable struct RequestException <: Exception
    error::String
end
mutable struct HttpException <: Exception end

function makerequest(m::Any, http::AbstractHttp)
    query_vars = toquery(m)
    name = method_name(typeof(m))
    url = "https://slack.com/api/$(name)"
    resp = post(http, url; query=query_vars)
    if statuscode(resp) != 200
        throw(HttpException())
    end
    body = text(resp)
    status = DandelionSlack.deserialize(Status, body)
    if !status.ok
        throw(RequestException(get(status.error)))
    end
    response_type = getresponsetype(typeof(m))

    status, DandelionSlack.deserialize(response_type, body)
end
