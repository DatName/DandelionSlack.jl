export MessageEvent

@slackevent(MessageEvent, "message",
    begin
        text::UTF8String
        channel::ChannelId
    end)