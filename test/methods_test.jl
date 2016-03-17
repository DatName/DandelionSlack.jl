using FactCheck
using DandelionSlack

import DandelionSlack.post

type MockHttpResponse
    code::Int
    body::AbstractString
end

type MethodTestCase
    test::AbstractString
    request_type::AbstractString
    request::RtmStart
    http_response::MockHttpResponse
    expected_status::Status
    expected_response::Nullable{RtmStartResponse}
end

type MockHttp <: DandelionSlack.AbstractHttp
    rv::Any
end

function post(m::MockHttp, url::AbstractString; query=Dict{AbstractString, Any}())
    m.rv
end

facts("Slack method tests") do
    tc_json = JSON.parsefile("test/tc_rtm.start.json")
    tc = DandelionSlack.deserialize(MethodTestCase, tc_json)
    mock_http = MockHttp(tc.http_response)
    @fact DandelionSlack.makerequest(tc.request, mock_http) -->
        (tc.expected_status, get(tc.expected_response))

    tc_json = JSON.parsefile("test/tc_rtm.start_2.json")
    tc = DandelionSlack.deserialize(MethodTestCase, tc_json)
    mock_http = MockHttp(tc.http_response)
    @fact_throws DandelionSlack.RequestException DandelionSlack.makerequest(tc.request, mock_http)
end