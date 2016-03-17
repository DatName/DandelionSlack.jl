export Status
export SlackMethod
export AbstractHttp

abstract SlackMethod
abstract AbstractHttp

immutable Status
    ok::Bool
    error::Nullable{AbstractString}
    warnings::Nullable{AbstractString}
end

function makerequest(m::SlackMethod, http::AbstractHttp)
    query_vars = toquery(m)
    name = method_name(typeof(m))
    url = "https://slack.com/api/$(name)"
    println(methods(post))
    resp = post(http, url; query=query_vars)
    println("$(resp)")
    status = deserialize(Status, resp.body)
    println("Returning status $(status)")

    status
end
