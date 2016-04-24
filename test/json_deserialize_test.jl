import Base.==

input = "{ \"bar\": { \"fnord\": 17 }, \"fizz\": 3.14 }"
json_string_input = """{"buzz":"abc", "bar": {"fnord": 42}}"""

immutable Bar
    fnord::Int
end

immutable Foo
    bar::Bar
end

immutable Baz
    fizz::Nullable{Float64}
    bar::Bar
end

immutable Qux
    buzz::Nullable{UTF8String}
    bar::Bar
end

immutable Foobar
    bar::Nullable{Bar}
end

function ==(a::Foobar, b::Foobar)
    !isnull(a.bar) && !isnull(b.bar) && get(a.bar) == get(b.bar) || isnull(a.bar) && isnull(b.bar)
end

function ==(a::Qux, b::Qux)
    eq_buzz = !isnull(a.buzz) && !isnull(b.buzz) && get(a.buzz) == get(b.buzz) ||
        isnull(a.buzz) && isnull(b.buzz)
    a.bar == b.bar && eq_buzz
end

immutable JsonArray
    foo::Int
    bar::Array{Bar}
    fizz::Array{Int}
end

function ==(a::JsonArray, b::JsonArray)
    a.foo == b.foo && a.bar == b.bar && a.fizz == b.fizz
end

immutable TestResponse
    ok::Bool
    warnings::Nullable{AbstractString}
    error::Nullable{AbstractString}
end

function ==(a::TestResponse, b::TestResponse)
    eq_warns = !isnull(a.warnings) && !isnull(b.warnings) && get(a.warnings) == get(b.warnings) ||
        isnull(a.warnings) && isnull(b.warnings)
    eq_errors = !isnull(a.error) && !isnull(b.error) && get(a.error) == get(b.error) ||
        isnull(a.error) && isnull(b.error)
    a.ok == b.ok && eq_warns && eq_errors
end

@test DandelionSlack.deserialize(Foo, input) == Foo(Bar(17))
@test DandelionSlack.deserialize(Baz, input) == Baz(Nullable(3.14), Bar(17))
@test DandelionSlack.deserialize(Qux, input) == Qux(Nullable{UTF8String}(),Bar(17))

facts("JSON deserialization") do
    # Testing this function
    # deserialize{T}(::Type{Nullable{T}}, json::AbstractString) = deserialize(T, json)
    @fact DandelionSlack.deserialize(Qux, json_string_input) -->
        Qux(Nullable("abc"), Bar(42))

    # Testing this function
    # deserialize{T}(::Type{Nullable{T}}, json::Dict) = deserialize(T, json)
    @fact DandelionSlack.deserialize(Foobar, "{}") --> Foobar(Nullable{Bar}())
    @fact DandelionSlack.deserialize(Foobar, "{\"bar\": {\"fnord\": 42}}") -->
        Foobar(Nullable(Bar(42)))
end

facts("JSON deserialization of arrays") do
    json_with_array = """{"foo": 42, "bar":[{"fnord": 17}, {"fnord": 13}], "fizz": [1,2,3]}"""
    bars = [Bar(17), Bar(13)]
    @fact DandelionSlack.deserialize(JsonArray, json_with_array) -->
        JsonArray(42, bars, [1,2,3])
end

test_response = """{"ok": true, "warnings": "a warning"}"""
@test DandelionSlack.deserialize(TestResponse, test_response) ==
    TestResponse(true, "a warning", Nullable{AbstractString}())

test_response = """{"ok": true, "warnings": null}"""
@test DandelionSlack.deserialize(TestResponse, test_response) ==
    TestResponse(true, Nullable{AbstractString}(), Nullable{AbstractString}())
