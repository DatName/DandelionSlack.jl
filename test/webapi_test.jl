using FactCheck
using DandelionSlack

facts("WebApi rtm") do
    @fact toparam(RtmStart("foo", "1", "2", "3")) --> Dict(
        "token" => "foo",
        "simple_latest" => "1",
        "no_unreads" => "2",
        "mpim_aware" => "3")

    @fact toparam(RtmStart("foo", "1", "2", Nullable{AbstractString}())) --> Dict(
        "token" => "foo",
        "simple_latest" => "1",
        "no_unreads" => "2")

    @fact toparam(RtmStart("foo", "1", Nullable{AbstractString}(), Nullable{AbstractString}())) -->
        Dict("token" => "foo", "simple_latest" => "1")
end