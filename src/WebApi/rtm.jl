export
    RtmStart,
    RtmStartResponse

import Base.==

immutable RtmStart
    token::AbstractString
    simple_latest::Nullable{AbstractString}
    no_unreads::Nullable{AbstractString}
    mpim_aware::Nullable{AbstractString}
end

immutable RtmStartResponse
    url::AbstractString
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