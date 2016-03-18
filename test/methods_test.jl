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

function test_successful_method(tc::MethodTestCase)
    mock_http = MockHttp(tc.http_response)
    @fact DandelionSlack.makerequest(tc.request, mock_http) -->
        (tc.expected_status, get(tc.expected_response))
end

function test_method_error(tc::MethodTestCase)
    mock_http = MockHttp(tc.http_response)
    @fact_throws DandelionSlack.RequestException DandelionSlack.makerequest(tc.request, mock_http)
end

facts("Slack method tests") do
    testcase_dir = "test/testcases"
    testcase_dir_entries = readdir(testcase_dir)
    istestcase = x -> isfile(joinpath(testcase_dir, string(x))) && endswith(x, ".json")
    testcases = filter(istestcase, testcase_dir_entries)

    for testcase_file in testcases
        context("Test case $(testcase_file)") do
            tc_json = JSON.parsefile(joinpath(testcase_dir, string(testcase_file)))
            tc = DandelionSlack.deserialize(MethodTestCase, tc_json)

            if tc.test == "MethodCall"
                test_successful_method(tc)
            elseif tc.test == "MethodCallError"
                test_method_error(tc)
            else
                throws(Exception("Unexpected test type $(tc.test)"))
            end
        end
    end
end