export HelloEvent,
       OutgoingPingEvent,
       RTMError,
       ErrorEvent

@slackevent(HelloEvent, "hello", begin end)

@slackoutevent(OutgoingPingEvent, "ping", begin end)

immutable RTMError
    code::Int64
    msg::UTF8String
end

@slackevent(ErrorEvent, "error", begin
        error::RTMError
    end)

@slackevent(PresenceChangeEvent, "presence_change", begin
        presence::UTF8String
        user::UserId
    end)

@slackevent(UserTypingEvent, "user_typing", begin
        channel::ChannelId
        user::UserId
    end)

@slackevent(ReconnectUrlEvent, "reconnect_url", begin
        url::UTF8String
    end)