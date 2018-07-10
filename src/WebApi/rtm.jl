export
    RtmStart,
    RtmStartResponse

import Base.==

@slackmethod(RtmStart, "rtm.start",
begin
    simple_latest::Nullable{String}
    no_unreads::Nullable{String}
    mpim_aware::Nullable{String}
end,

begin
    url::String
    self::Self
    team::Team
    users::Vector{User}
    channels::Vector{SlackChannel}
    groups::Vector{Group}
    mpims::Nullable{Vector{Mpim}}
    ims::Vector{Im}
    bots::Vector{Bot}
end)

==(a::RtmStartResponse, b::RtmStartResponse) = a.url == b.url

