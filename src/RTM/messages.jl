export HelloEvent,
       OutgoingMessageEvent,
       MessageEvent,
       MessageAckEvent

@slackevent(HelloEvent, "hello", begin end)

@slackoutevent(OutgoingPingEvent, "ping", begin end)

@slackoutevent(OutgoingMessageEvent, "message",
    begin
        text::UTF8String
        channel::ChannelId
    end)

@slackevent(MessageEvent, "message",
    begin
        text::UTF8String
        channel::ChannelId
    end)

@slackevent(MessageAckEvent, "message_ack",
    begin
        text::UTF8String
        channel::UTF8String
        ok::Bool
    end)