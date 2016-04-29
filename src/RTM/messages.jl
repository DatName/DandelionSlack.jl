export HelloEvent,
       OutgoingMessageEvent,
       MessageEvent

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