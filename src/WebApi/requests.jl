export requests

import Requests

type RequestsHttpResponse
    r::Requests.Response
end

statuscode(resp::RequestsHttpResponse) = Requests.statuscode(resp.r)
text(resp::RequestsHttpResponse) = Requests.text(resp.r)

type RequestsHttp <: AbstractHttp end

post(::RequestsHttp, uri::AbstractString; args...) =
    RequestsHttpResponse(Requests.post(Requests.URI(uri); args...))

requests = RequestsHttp()