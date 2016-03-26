using FactCheck
using DandelionSlack

import DandelionSlack.post
import Base.==

##
## Define a fake method, so we don't have to use an actual Slack method,
## because they're complex.
##
immutable FakeMethod
    token::UTF8String
end

immutable FakeMethodResponse
    url::UTF8String
end

DandelionSlack.getresponsetype(::Type{FakeMethod}) = FakeMethodResponse
DandelionSlack.method_name(::Type{FakeMethod}) = "fake.method"

==(a::FakeMethodResponse, b::FakeMethodResponse) = a.url == b.url

type MockHttpResponse
    code::Int
    body::AbstractString
end


type MethodTestCase
    test::AbstractString
    request::FakeMethod
    http_response::MockHttpResponse
    expected_status::Status
    expected_response::Nullable{FakeMethodResponse}
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

function test_http_call_error(tc::MethodTestCase)
    mock_http = MockHttp(tc.http_response)
    @fact_throws DandelionSlack.HttpException DandelionSlack.makerequest(tc.request, mock_http)
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
            elseif tc.test == "HttpCallError"
                test_http_call_error(tc)
            else
                throws(Exception("Unexpected test type $(tc.test)"))
            end
        end
    end
end