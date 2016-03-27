export
    ChannelsList,
    ChannelsListResponse,
    ChannelsInfo,
    ChannelsInfoResponse,
    ChannelsArchive,
    ChannelsArchiveResponse

##
## channels.list
##

immutable ChannelsList
    token::Token
    exclude_archived::Nullable{Int64}
end

immutable ChannelsListResponse
    channels::Array{Channel}
end

getresponsetype(::Type{ChannelsList}) = ChannelsListResponse
method_name(::Type{ChannelsList}) = "channels.list"

##
## channels.info
##

immutable ChannelsInfo
    token::Token
    channel::ChannelId
end

immutable ChannelsInfoResponse
    channel::Channel
end

getresponsetype(::Type{ChannelsInfo}) = ChannelsInfoResponse
method_name(::Type{ChannelsInfo}) = "channels.info"

##
## channels.archive
##

immutable ChannelsArchive
    token::Token
    channel::ChannelId
end

# Note: ChannelsArchiveResponse is intentionally empty, because we get no more information back than
# the status.
immutable ChannelsArchiveResponse
end

getresponsetype(::Type{ChannelsArchive}) = ChannelsArchiveResponse
method_name(::Type{ChannelsArchive}) = "channels.archive"

