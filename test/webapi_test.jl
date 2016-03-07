using FactCheck
using DandelionSlack

facts("WebApi rtm") do
    @fact toparam(RtmStart("foo", "1", "2", "3")) --> Dict(
        "token" => "foo",
        "simple_latest" => "1",
        "no_unreads" => "2",
        "mpim_aware" => "3")
end