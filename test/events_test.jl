facts("Outgoing events") do
    context("OutgoingMessageEvent") do
        s = DandelionSlack.serialize(OutgoingMessageEvent(utf8("Hello"), ChannelId("C0")))
        @fact s["type"] --> utf8("message")
        @fact s["text"] --> utf8("Hello")
        @fact s["channel"] --> ChannelId("C0")
        # Id is set when sending the message, not when serializing.
        @fact haskey(s, "id") --> false
    end

    context("OutgoingPingEvent") do
        s = DandelionSlack.serialize(DandelionSlack.OutgoingPingEvent())
        @fact s["type"] --> utf8("ping")
        @fact haskey(s, "id") --> false
    end
end