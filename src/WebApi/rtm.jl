export toparam
export RtmStart
export RtmStartResponse

immutable RtmStart <: SlackMethod
    token::AbstractString
    simple_latest::Nullable{AbstractString}
    no_unreads::Nullable{AbstractString}
    mpim_aware::Nullable{AbstractString}
end

immutable RtmStartResponse

end

getresponsetype(::Type{RtmStart}) = RtmStartResponse
method_name(::Type{RtmStart}) = "rtm.start"