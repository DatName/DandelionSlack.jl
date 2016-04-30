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
    users::Array{User}
    channels::Array{SlackChannel}
    groups::Array{Group}
    mpims::Nullable{Array{Mpim}}
    ims::Array{Im}
    bots::Array{Bot}
end)

==(a::RtmStartResponse, b::RtmStartResponse) = a.url == b.url

