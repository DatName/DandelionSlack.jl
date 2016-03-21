using FactCheck
using DandelionSlack

positive_tests = Dict{DataType, Any}(
    Id => [
        (Id("foo"), "foo")
    ],
    Self => [
        (Self(Id("fakeid"), Name("My Name"), 123456, "yes"),
            """{"id": "fakeid", "name": "My Name", "created": 123456, "manual_presence": "yes"}""")
    ]
)

facts("Test deserialization of Slack types") do
    for (datatype, testcases) in positive_tests
        context("Positive testcases for $(datatype)") do
            for t in testcases
                expected = t[1]
                json_source = t[2]
                @fact DandelionSlack.deserialize(datatype, json_source) --> expected
            end
        end
    end
end
