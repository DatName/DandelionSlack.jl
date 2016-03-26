export
    ChannelsList,
    ChannelsListResponse

immutable ChannelsList
    token::Token
    exclude_archived::Nullable{Int64}
end

immutable ChannelsListResponse
    channels::Array{Channel}
end

getresponsetype(::Type{ChannelsList}) = ChannelsListResponse
method_name(::Type{ChannelsList}) = "channels.list"