# This test file test that deserialization of method responses from Slack
# execute wihout errors.
#
# The tests are not actually present in this git repository. These tests
# come from the "Tester" tab in the Slack API pages for each method. The issue is that they
# come from actual requests done by my user, and so they contain a bunch of data which I
# might not want public, I believe including the test token provided by Slack. Therefore
# each test is located on my machine only, and is ignored by the .gitignore file.
#
# Note that these tests don't check that the deserialized fields have the correct values.
# Primarily these tests confirm those fields that are mandatory, and those that are optional.
# When creating the first of these test methods I came across many fields which are optional,
# because they're not present in the JSON response, but were marked as mandatory in our code.
# In the distant future I will add that functionality to these tests though. Each test file
# will have a companion Julia file which contains the expected deserialized object. It's
# time consuming to write tests though.

facts("Deserializing Slack Tester examples") do
    testcase_dir = "test/slacktester"
    rel_testcase_dir = "slacktester"
    istestcase = x -> isfile(joinpath(testcase_dir, string(x))) && endswith(x, ".json")
    testcase_dir_entries = []

    try
        testcase_dir_entries = readdir(testcase_dir)
    catch ex
        isa(ex, SystemError) || rethrow(ex)
        println("No test/slacktester directory found, so not testing Slack examples.")
        return
    end

    testcases = filter(istestcase, testcase_dir_entries)

    for testcase_file in testcases
        context("$(testcase_file)") do
            testcase_with_path = joinpath(testcase_dir, string(testcase_file))
            jl_file, _json_ext = splitext(testcase_file)
            jl_file_with_path = joinpath(rel_testcase_dir, jl_file * ".jl")
            datatype = eval(evalfile(jl_file_with_path))
            tc_json = JSON.parsefile(testcase_with_path)
            DandelionSlack.deserialize(datatype, tc_json)
        end
    end
end