using FactCheck
using DandelionSlack

facts("WebApi rtm") do
    @fact toquery(RtmStart("foo", "1", "2", "3")) --> Dict(
        "token" => "foo",
        "simple_latest" => "1",
        "no_unreads" => "2",
        "mpim_aware" => "3")

    @fact toquery(RtmStart("foo", "1", "2", Nullable{AbstractString}())) --> Dict(
        "token" => "foo",
        "simple_latest" => "1",
        "no_unreads" => "2")

    @fact toquery(RtmStart("foo", "1", Nullable{AbstractString}(), Nullable{AbstractString}())) -->
        Dict("token" => "foo", "simple_latest" => "1")
end