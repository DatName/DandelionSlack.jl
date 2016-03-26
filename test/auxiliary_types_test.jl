using FactCheck
using DandelionSlack

@newimmutable NewFoo{T} <: Integer
@newtype NewBar{T <: AbstractString} <: AbstractString

facts("New types") do
    @fact SlackId("abc") --> SlackId("abc")
    @fact SlackId("abc") --> not(SlackId("foo"))

    takes_id(a::SlackId) = a
    @fact_throws MethodError takes_id(SlackName("abc"))

    newfoo = NewFoo{Int}(1)
    @fact typeof(newfoo.v) --> Int
    @fact newfoo.v         --> 1

    newbar = NewBar{UTF8String}(utf8("bar"))
    @fact typeof(newbar.v) --> UTF8String
    @fact newbar.v         --> utf8("bar")
end