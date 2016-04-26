export HelloEvent,
       MessageEvent

@slackevent(HelloEvent, "hello", begin end)

@slackevent(MessageEvent, "message",
    begin
        text::UTF8String
        channel::ChannelId
    end)