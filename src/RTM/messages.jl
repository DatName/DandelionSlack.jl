export OutgoingMessageEvent,
       MessageEvent,
       MessageAckEvent

@slackoutevent(OutgoingMessageEvent, "message",
    begin
        text::String
        channel::ChannelId
    end)

@slackevent(MessageEvent, "message",
    begin
        text::String
        channel::ChannelId
        user::UserId
        ts::EventTimestamp
    end)

@slackevent(MessageAckEvent, "message_ack",
    begin
        text::String
        channel::Nullable{String}
        ok::Bool
        ts::EventTimestamp
    end)
