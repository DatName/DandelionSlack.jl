using Requests

immutable Status
    ok::Bool

end

#function makerequest{T}(url::AbstractString, t::T)
#    query_vars = toquery(t)
#    req = post(url, query_vars)
#
#end