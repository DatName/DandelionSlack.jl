export toparam
export RtmStart

immutable RtmStart
    token::AbstractString
    simple_latest::Nullable{AbstractString}
    no_unreads::Nullable{AbstractString}
    mpim_aware::Nullable{AbstractString}
end

function toparam(r::RtmStart)
    params = Dict("token" => r.token)

    if !isnull(r.simple_latest)
        params["simple_latest"] = get(r.simple_latest)
    end

    if !isnull(r.no_unreads)
        params["no_unreads"] = get(r.no_unreads)
    end

    if !isnull(r.mpim_aware)
        params["mpim_aware"] = get(r.mpim_aware)
    end

    params
end