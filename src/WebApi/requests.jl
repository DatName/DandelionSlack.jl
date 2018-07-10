export real_requests

import Requests

mutable struct RequestsHttpResponse
    r::Requests.Response
end

statuscode(resp::RequestsHttpResponse) = Requests.statuscode(resp.r)
text(resp::RequestsHttpResponse) = Requests.text(resp.r)

mutable struct RequestsHttp <: AbstractHttp end

post(::RequestsHttp, uri::AbstractString; args...) =
    RequestsHttpResponse(Requests.post(Requests.URI(uri); args...))

real_requests = RequestsHttp()
