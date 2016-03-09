using FactCheck
import DandelionSlack

type Foo
    foo::AbstractString
    bar::Bool
    baz::Nullable{AbstractString}
end

facts("Deserialize, with nullable") do

    @fact DandelionSlack.deserialize(Foo, """{"foo": "abc", "bar": true, "baz": "def"}""") -->
        Foo("abc", true, "def")
    @fact DandelionSlack.deserialize(Foo, """{"foo": "abc", "bar": false, "baz": "def"}""") -->
        Foo("abc", false, "def")
    @fact DandelionSlack.deserialize(Foo, """{"foo": "abc", "bar": false}""") -->
        Foo("abc", false, Nullable{AbstractString}())

end