using FactCheck
using DandelionSlack

@newimmutable NewFoo{T} <: Integer
@newtype NewBar{T <: AbstractString} <: AbstractString

@newimmutable NewBaz <: UTF8String
@stringinterface NewBaz

@newtype NewQux <: UTF8String
@stringinterface NewBaz

@newtype NewFnord <: Int64

facts("New types") do
    @fact UserId("abc") --> UserId("abc")
    @fact UserId("abc") --> not(UserId("foo"))

    takes_id(a::UserId) = a
    @fact_throws MethodError takes_id(SlackName("abc"))

    newfoo = NewFoo{Int}(1)
    @fact typeof(newfoo.v) --> Int
    @fact newfoo.v         --> 1

    newbar = NewBar{UTF8String}(utf8("bar"))
    @fact typeof(newbar.v) --> UTF8String
    @fact newbar.v         --> utf8("bar")

    newbaz = NewBaz(utf8("baz"))
    @fact typeof(newbaz.v) --> UTF8String
    @fact_throws MethodError NewBaz(1)

    newqux = NewQux(utf8("qux"))
    @fact typeof(newqux.v) --> UTF8String
    @fact newqux.v --> utf8("qux")
    newqux.v = "qux2"
    @fact newqux.v --> utf8("qux2")
    @fact_throws MethodError NewBaz(1)

    @fact NewFnord(123).v --> 123
end