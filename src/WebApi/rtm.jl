export
    RtmStart,
    RtmStartResponse

import Base.==

immutable RtmStart
    token::UTF8String
    simple_latest::Nullable{UTF8String}
    no_unreads::Nullable{UTF8String}
    mpim_aware::Nullable{UTF8String}
end

immutable RtmStartResponse
    url::UTF8String
    self::Self
    team::Team
    users::Array{User}
    channels::Array{Channel}
    groups::Array{Group}
    mpims::Nullable{Array{Mpim}}
    ims::Array{Im}
    bots::Array{Bot}
end

==(a::RtmStartResponse, b::RtmStartResponse) = a.url == b.url

getresponsetype(::Type{RtmStart}) = RtmStartResponse
method_name(::Type{RtmStart}) = "rtm.start"