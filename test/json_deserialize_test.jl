using FactCheck
import Base.==
import DandelionSlack



type Foo
    foo::AbstractString
    bar::Bool
    baz::Nullable{AbstractString}
end

function ==(a::Foo, b::Foo)
	be = !isnull(a.baz) && !isnull(b.baz) && get(a.baz) == get(b.baz) || isnull(a.baz) && isnull(b.baz) 
	a.foo == b.foo && a.bar == b.bar && be
end

facts("Deserialize, with nullable") do

    @fact DandelionSlack.deserialize(Foo, """{"foo": "abc", "bar": true, "baz": "def"}""") -->
        Foo("abc", true, "def")
    @fact DandelionSlack.deserialize(Foo, """{"foo": "abc", "bar": false, "baz": "def"}""") -->
        Foo("abc", false, "def")
    @fact DandelionSlack.deserialize(Foo, """{"foo": "abc", "bar": false}""") -->
        Foo("abc", false, Nullable{AbstractString}())

end