export
    ChannelsList,
    ChannelsListResponse,
    ChannelsInfo,
    ChannelsInfoResponse,
    ChannelsArchive,
    ChannelsArchiveResponse,
    ChannelsJoin,
    ChannelsJoinResponse

@slackmethod(ChannelsList, "channels.list",
    begin
        exclude_archived::Nullable{Int64}
    end,

    begin
        channels::Array{SlackChannel,1}
    end)

@slackmethod(ChannelsInfo, "channels.info",
    begin
        channel::ChannelId
    end,

    begin
        channel::SlackChannel
    end)

@slackmethod(ChannelsArchive, "channels.archive",
    begin
        channel::ChannelId
    end,

    # Note: ChannelsArchiveResponse is intentionally empty, because we get no more information back than
    # the status.
    begin
    end)

@slackmethod(ChannelsJoin, "channels.join",
    begin
        name::String
    end,

    begin
        already_in_channel::Nullable{Bool}
        # TODO: The "channel" object here might be a limited channel type.
    end)
