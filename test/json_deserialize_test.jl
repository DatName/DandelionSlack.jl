using FactChecks

type Foo
    foo::AbstractString
    bar::Bool
    baz::Nullable{AbstractString}
end

facts("Deserialize, with nullable") do

    @fact deserialize(Foo, """{"foo": "abc", "bar": true, "baz": "def"}""") -->
        Foo("abc", true, "def")
    @fact deserialize(Foo, """{"foo": "abc", "bar": false, "baz": "def"}""") -->
        Foo("abc", false, "def")
    @fact deserialize(Foo, """{"foo": "abc", "bar": false}""") -->
        Foo("abc", false, Nullable{AbstractString}())

end