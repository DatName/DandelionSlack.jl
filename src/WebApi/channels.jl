export
    ChannelsList,
    ChannelsListResponse,
    ChannelsInfo,
    ChannelsInfoResponse,
    ChannelsArchive,
    ChannelsArchiveResponse

@slackmethod(ChannelsList, "channels.list",
    begin
        exclude_archived::Nullable{Int64}
    end,

    begin
        channels::Array{Channel}
    end)

@slackmethod(ChannelsInfo, "channels.info",
    begin
        channel::ChannelId
    end,

    begin
        channel::Channel
    end)

@slackmethod(ChannelsArchive, "channels.archive",
    begin
        channel::ChannelId
    end,

    # Note: ChannelsArchiveResponse is intentionally empty, because we get no more information back than
    # the status.
    begin
    end)


