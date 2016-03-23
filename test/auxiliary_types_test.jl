using FactCheck
using DandelionSlack

facts("New types") do
    @fact Id("abc") --> Id("abc")
    @fact Id("abc") --> not(Id("foo"))

    takes_id(a::Id) = a
    @fact_throws MethodError takes_id(Name("abc"))
end