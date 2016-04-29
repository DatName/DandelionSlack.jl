using WebSocketClient
import JSON
import Base.==
import DandelionSlack: on_event, on_reply, on_error

#
# A fake RTM event.
#

immutable FakeEvent <: DandelionSlack.OutgoingEvent
    value::UTF8String

    FakeEvent() = new("")
    FakeEvent(a::ASCIIString) = new(utf8(a))
end

==(a::FakeEvent, b::FakeEvent) = a.value == b.value

DandelionSlack.serialize(event::FakeEvent) = Dict{AbstractString, Any}("value" => event.value)

test_event_1 = FakeEvent("bar")
test_event_2 = FakeEvent("baz")

# Also add equality for all events, for testing convenience.
macro eventeq(r::Expr)
    quote
        function $(esc(:(==)))(a::$r, b::$r)
            if typeof(a) != typeof(b)
                return false
            end

            for name in fieldnames(a)
                af = getfield(a, name)
                bf = getfield(b, name)

                if isa(af, Nullable)
                    null_equals = isnull(af) && isnull(bf) || !isnull(af) && !isnull(bf) && get(af) == get(bf)
                    if !null_equals
                        return false
                    end
                else
                    if af != bf
                        return false
                    end
                end
            end

            return true
        end
    end
end

@eventeq DandelionSlack.OutgoingEvent
@eventeq DandelionSlack.Event

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

function expect_sent_event(c::MockWSClient, id::Int64, value::UTF8String)
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
    reply_events::Vector{Tuple{Int64, DandelionSlack.Event}}
    events::Vector{DandelionSlack.Event}
    errors::Vector{Symbol}

    MockRTMHandler() = new([], [], [])
end

on_reply(h::MockRTMHandler, id::Int64, event::DandelionSlack.Event) =
    push!(h.reply_events, (id, event))

on_event(h::MockRTMHandler, event::DandelionSlack.Event) = push!(h.events, event)
on_error(h::MockRTMHandler, reason::Symbol, text::UTF8String) = push!(h.errors, reason)

function expect_reply(h::MockRTMHandler, id::Int64, event::DandelionSlack.MessageEvent)
    @fact isempty(h.reply_events) --> false

    actual_id, actual_event = shift!(h.reply_events)
    @fact actual_id --> id
    @fact actual_event --> event
end

function expect_event(h::MockRTMHandler, event::DandelionSlack.Event)
    @fact isempty(h.events) --> false
    @fact shift!(h.events) --> event
end

function expect_error(h::MockRTMHandler, reason::Symbol)
    @fact isempty(h.errors) --> false
    @fact shift!(h.errors) --> reason
end

#
# Tests
#

facts("RTM event register") do
    @fact DandelionSlack.find_event("message") --> MessageEvent
    @fact DandelionSlack.find_event("nosuchevent") --> nothing
end

facts("RTM events") do
    context("Event equality for testing") do
        @fact MessageEvent("a", ChannelId("b")) --> MessageEvent("a", ChannelId("b"))
        @fact MessageEvent("a", ChannelId("b")) != MessageEvent("b", ChannelId("c")) --> true
        @fact OutgoingMessageEvent("a", ChannelId("b")) --> OutgoingMessageEvent("a", ChannelId("b"))
        @fact OutgoingMessageEvent("a", ChannelId("b")) != OutgoingMessageEvent("b", ChannelId("c")) --> true
    end

    context("Deserialize events") do
        message_json = """{"id": 1, "type": "message", "text": "Hello", "channel": "C0"}"""
        message = DandelionSlack.deserialize(MessageEvent, message_json)

        @fact message --> MessageEvent(utf8("Hello"), ChannelId("C0"))
    end

    context("Increasing message id") do
        ws_client = MockWSClient()
        mock_handler = MockRTMHandler()
        rtm = DandelionSlack.RTMClient(mock_handler, ws_client)

        message_id_1 = DandelionSlack.send_event(rtm, FakeEvent())
        message_id_2 = DandelionSlack.send_event(rtm, FakeEvent())
        message_id_3 = DandelionSlack.send_event(rtm, FakeEvent())

        @fact message_id_1 < message_id_2 < message_id_3 --> true
    end

    context("Sending events") do
        ws_client = MockWSClient()
        mock_handler = MockRTMHandler()
        rtm = DandelionSlack.RTMClient(mock_handler, ws_client)

        id_1 = DandelionSlack.send_event(rtm, test_event_1)
        id_2 = DandelionSlack.send_event(rtm, test_event_2)

        expect_sent_event(ws_client, id_1, test_event_1.value)
        expect_sent_event(ws_client, id_2, test_event_2.value)
    end

    context("Send close on user request") do
        ws_client = MockWSClient()
        mock_handler = MockRTMHandler()
        rtm = DandelionSlack.RTMClient(mock_handler, ws_client)
        DandelionSlack.close(rtm)
        expect_close(ws_client)
    end

    context("Propagate events from WebSocket to RTM") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)

        on_text(rtm_ws, utf8("""{"type": "message", "channel": "C0", "text": "Hello"}"""))

        expect_event(mock_handler, MessageEvent(utf8("Hello"), ChannelId(utf8("C0"))))
    end

    context("Reply event") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)

        on_text(rtm_ws,
            utf8("""{"reply_to": 1, "type": "message", "text": "Hello", "channel": "C0"}"""))

        expect_reply(mock_handler, 1, MessageEvent(utf8("Hello"), ChannelId("C0")))
    end

    context("Missing type key") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)

        on_text(rtm_ws, utf8("""{"reply_to": 1}"""))

        expect_error(mock_handler, :missing_type)
    end

    context("Invalid JSON") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)

        on_text(rtm_ws, utf8("""{"reply_to" foobarbaz"""))

        expect_error(mock_handler, :invalid_json)
    end
end

facts("RTM integration") do
    context("Send and receive events") do
        url = Requests.URI("wss://some/url/to/rtm")
        actual_url = nothing
        mock_ws = MockWSClient()
        mock_handler = MockRTMHandler()
        rtm_ws = nothing
        function ws_client_factory(uri, handler)
            actual_url = url
            rtm_ws = handler
            mock_ws
        end

        rtm_client = rtm_connect(url, mock_handler; ws_client_factory=ws_client_factory)

        # These are fake events from the WebSocket
        on_text(rtm_ws, utf8("""{"type": "hello"}"""))

        # These are the events we expect.
        expect_event(mock_handler, HelloEvent())
    end
end