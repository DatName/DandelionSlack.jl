export toparam
export RtmStart

immutable RtmStart
    token::AbstractString
    simple_latest::Nullable{AbstractString}
    no_unreads::Nullable{AbstractString}
    mpim_aware::Nullable{AbstractString}
end

