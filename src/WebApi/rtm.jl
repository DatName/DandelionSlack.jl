export toparam
export RtmStart
export RtmStartResponse

import Base.==

immutable RtmStart <: SlackMethod
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
    mpims::Array{Mpim}
    ims::Array{Im}
    bots::Array{Bot}
end

function ==(a::RtmStartResponse, b::RtmStartResponse)
    return a.url == b.url
end

getresponsetype(::Type{RtmStart}) = RtmStartResponse
method_name(::Type{RtmStart}) = "rtm.start"