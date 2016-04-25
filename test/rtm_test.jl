using WebSocketClient
import JSON
import Base.==

#
# A fake RTM event.
#

immutable FakeEvent <: DandelionSlack.RTMEvent
    value::UTF8String

    FakeEvent() = new("")
    FakeEvent(a::ASCIIString) = new(utf8(a))
end

==(a::FakeEvent, b::FakeEvent) = a.value == b.value

DandelionSlack.serialize(event::FakeEvent) = Dict{AbstractString, Any}("value" => event.value)

test_event_1 = FakeEvent("bar")
test_event_2 = FakeEvent("baz")

#
# Implement a mock WebSocket client that stores the events we send.
#

type MockWSClient <: AbstractWSClient
    sent::Vector{Dict{Any, Any}}
    closed_called::Int

    MockWSClient() = new([], 0)
end

WebSocketClient.stop(c::MockWSClient)                     = c.closed_called += 1
WebSocketClient.send_text(c::MockWSClient, s::UTF8String) = push!(c.sent, JSON.parse(s))

function expect_event(c::MockWSClient, id::Int64, value::UTF8String)
    @fact c.sent --> x -> !isempty(x)

    parsed = shift!(c.sent)
    @fact parsed["id"] --> id
    @fact parsed["value"] --> value
end

expect_close(c::MockWSClient; no_of_closes::Int=1) = @fact c.closed_called --> no_of_closes

#
# A mock RTMHandler to test that RTMWebSocket propagates messages correctly.
#

type MockRTMHandler <: RTMHandler
    events::Vector{Tuple{Int64, DandelionSlack.RTMEvent}}

    MockRTMHandler() = new([])
end

DandelionSlack.on_event(h::MockRTMHandler, id::Int64, event::DandelionSlack.RTMEvent) =
    push!(h.events, (id, event))

function expect_event(h::MockRTMHandler, id::Int64, event::DandelionSlack.RTMEvent)
    @fact isempty(h.events) --> false

    actual_id, actual_event = shift!(h.events)
    @fact actual_id --> id
    @fact actual_event --> event
end

#
# Tests
#

facts("RTM events") do
    context("Increasing message id") do
        ws_client = MockWSClient()
        rtm = DandelionSlack.RTMClient(ws_client)

        message_id_1 = DandelionSlack.send_event(rtm, FakeEvent())
        message_id_2 = DandelionSlack.send_event(rtm, FakeEvent())
        message_id_3 = DandelionSlack.send_event(rtm, FakeEvent())

        @fact message_id_1 < message_id_2 < message_id_3 --> true
    end

    context("Sending events") do
        ws_client = MockWSClient()
        rtm = DandelionSlack.RTMClient(ws_client)

        id_1 = DandelionSlack.send_event(rtm, test_event_1)
        id_2 = DandelionSlack.send_event(rtm, test_event_2)

        expect_event(ws_client, id_1, test_event_1.value)
        expect_event(ws_client, id_2, test_event_2.value)
    end

    context("Send close on user request") do
        ws_client = MockWSClient()
        rtm = DandelionSlack.RTMClient(ws_client)
        DandelionSlack.close(rtm)
        expect_close(ws_client)
    end

    context("Propagate events from WebSocket to RTM") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)

        on_text(rtm_ws, utf8("""{"id": 1, "type": "message", "channel": "C0", "text": "Hello"}"""))

        expect_event(mock_handler, 1, Message(utf8("Hello"), ChannelId(utf8("C0"))))
    end
end
