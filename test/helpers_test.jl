
@slackmethod(TestMethodMacro, "method.macro",
    begin
        a::Int64
    end,

    begin
        b::UTF8String
        c::Int64
    end)

facts("Defining requests and responses with a macro") do
    req = TestMethodMacro(Token(utf8("foo")), Int64(42))
    @fact req.token --> utf8("foo")
    @fact req.a --> 42

    resp = TestMethodMacroResponse(utf8("bar"), 17)
    @fact resp.b --> utf8("bar")
    @fact resp.c --> 17

    @fact getresponsetype(TestMethodMacro) --> TestMethodMacroResponse
    @fact method_name(TestMethodMacro) --> "method.macro"
end
