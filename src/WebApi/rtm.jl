export
    RtmStart,
    RtmStartResponse

import Base.==

@slackmethod(RtmStart, "rtm.start",
begin
    simple_latest::Nullable{UTF8String}
    no_unreads::Nullable{UTF8String}
    mpim_aware::Nullable{UTF8String}
end,

begin
    url::UTF8String
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

