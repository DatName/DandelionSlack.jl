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