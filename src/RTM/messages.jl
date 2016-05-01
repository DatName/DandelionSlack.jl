export OutgoingMessageEvent,
       MessageEvent,
       MessageAckEvent

@slackoutevent(OutgoingMessageEvent, "message",
    begin
        text::UTF8String
        channel::ChannelId
    end)

@slackevent(MessageEvent, "message",
    begin
        text::UTF8String
        channel::ChannelId
        user::UserId
        ts::EventTimestamp
    end)

@slackevent(MessageAckEvent, "message_ack",
    begin
        text::UTF8String
        channel::Nullable{UTF8String}
        ok::Bool
        ts::EventTimestamp
    end)