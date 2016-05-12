using WebSocketClient
import JSON
import Base.==
import DandelionSlack: on_event, on_reply, on_error, EventTimestamp
import WebSocketClient: ProxyCall

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
@eventeq DandelionSlack.EventError

function ==(a::RTMError, b::RTMError)
    return a.code == b.code && a.msg == b.msg
end

#
# Implement a mock WebSocket client that stores the events we send.
#

type MockWSClient <: AbstractWSClient
    sent::Vector{Dict{Any, Any}}
    channel_sent::Vector{Dict{Any, Any}}
    closed_called::Int
    chan::Channel{ProxyCall}

    function MockWSClient()
        channel_sent = Vector{Dict{Any, Any}}()
        chan = Channel{ProxyCall}(32)
        @schedule begin
            for (sym, ms) in chan
                m = ms[1]
                push!(channel_sent, JSON.parse(m.data))
            end
        end
        new([], channel_sent, 0, chan)
    end
end

function WebSocketClient.stop(c::MockWSClient)
    close(c.chan)
    c.closed_called += 1
end
WebSocketClient.get_channel(c::MockWSClient) = c.chan
WebSocketClient.send_text(c::MockWSClient, s::UTF8String) = push!(c.sent, JSON.parse(s))

function expect_sent_event(c::MockWSClient, expected::Dict{Any,Any})
    @fact isempty(c.sent) --> false

    parsed = shift!(c.sent)
    @fact parsed --> expected
end

function expect_channel_sent_event(c::MockWSClient, expected::Dict{Any,Any})
    @fact isempty(c.channel_sent) --> false

    parsed = shift!(c.channel_sent)
    @fact parsed --> expected
end

expect_close(c::MockWSClient; no_of_closes::Int=1) = @fact c.closed_called --> no_of_closes

#
# A mock RTMHandler to test that RTMWebSocket propagates messages correctly.
#

type MockRTMHandler <: RTMHandler
    reply_events::Vector{Tuple{Int64, DandelionSlack.Event}}
    events::Vector{DandelionSlack.Event}
    errors::Vector{EventError}

    MockRTMHandler() = new([], [], [])
end

on_reply(h::MockRTMHandler, id::Int64, event::DandelionSlack.Event) =
    push!(h.reply_events, (id, event))

on_event(h::MockRTMHandler, event::DandelionSlack.Event) = push!(h.events, event)
on_error(h::MockRTMHandler, e::EventError) = push!(h.errors, e)

function expect_reply(h::MockRTMHandler, id::Int64, event::DandelionSlack.Event)
    @fact isempty(h.reply_events) --> false

    actual_id, actual_event = shift!(h.reply_events)
    @fact actual_id --> id
    @fact actual_event --> event
end

function expect_event(h::MockRTMHandler, event::DandelionSlack.Event)
    @fact isempty(h.events) --> false
    @fact shift!(h.events) --> event
end

function expect_error(h::MockRTMHandler, e::EventError)
    @fact isempty(h.errors) --> false
    @fact shift!(h.errors) --> e
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
        @fact MessageEvent("a", ChannelId("b"), UserId("U0"), EventTimestamp("123")) -->
            MessageEvent("a", ChannelId("b"), UserId("U0"), EventTimestamp("123"))
        @fact MessageEvent("a", ChannelId("b"), UserId("U0"), EventTimestamp("123")) !=
            MessageEvent("b", ChannelId("c"), UserId("U0"), EventTimestamp("123")) --> true
        @fact OutgoingMessageEvent("a", ChannelId("b")) --> OutgoingMessageEvent("a", ChannelId("b"))
        @fact OutgoingMessageEvent("a", ChannelId("b")) != OutgoingMessageEvent("b", ChannelId("c")) --> true
    end

    context("Deserialize events") do
        message_json = """{"id": 1, "type": "message", "text": "Hello",
            "channel": "C0", "user": "U0", "ts": "123"}"""
        message = DandelionSlack.deserialize(MessageEvent, message_json)

        @fact message --> MessageEvent(utf8("Hello"), ChannelId("C0"), UserId("U0"), EventTimestamp("123"))
    end

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

        expect_sent_event(ws_client, Dict{Any,Any}("id" => id_1, "value" => test_event_1.value))
        expect_sent_event(ws_client, Dict{Any,Any}("id" => id_2, "value" => test_event_2.value))
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

        on_text(rtm_ws, utf8("""{"type": "message", "channel": "C0",
            "text": "Hello", "user": "U0", "ts": "123"}"""))

        expect_event(mock_handler,
            MessageEvent(utf8("Hello"), ChannelId(utf8("C0")), UserId("U0"), EventTimestamp("123")))
    end

    context("Message ack event") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)

        on_text(rtm_ws,
            utf8("""{"reply_to": 1, "ok": true, "text": "Hello", "channel": "C0", "ts": "123"}"""))

        expect_reply(mock_handler, 1,
            MessageAckEvent(utf8("Hello"), Nullable(ChannelId("C0")), true, EventTimestamp("123")))
    end

    context("Missing type key and not message ack") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)

        text = utf8("""{"reply_to": 1}""")
        on_text(rtm_ws, text)

        expect_error(mock_handler, MissingTypeError(text))
    end

    context("Invalid JSON") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)

        text = utf8("""{"reply_to" foobarbaz""")
        on_text(rtm_ws, text)

        expect_error(mock_handler, InvalidJSONError(text))
    end

    context("Unknown message type") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)

        text = utf8("""{"type": "nosuchtype"}""")
        on_text(rtm_ws, text)

        expect_error(mock_handler, UnknownEventTypeError(text, utf8("nosuchtype")))
    end

    context("Missing required field") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)

        # No "text" field.
        text = utf8("""{"type": "message", "channel": "C0", "user": "U0", "ts": "123"}""")
        on_text(rtm_ws, text)

        expect_error(mock_handler, DeserializationError(utf8("text"), text, MessageEvent))
    end

    context("Error event from Slack") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)

        on_text(rtm_ws,
            utf8("""{"type": "error", "error": {"code": 1, "msg": "Reason"}}"""))

        expect_event(mock_handler, ErrorEvent(RTMError(1, "Reason")))
    end

    # This only tests that the callback functions on_close, on_create, on_closing exist, not that
    # they actually do anything.
    context("Existence of all WebSocketHandler interface functions") do
        mock_handler = MockRTMHandler()
        rtm_ws = DandelionSlack.RTMWebSocket(mock_handler)
        mock_ws_client = MockWSClient()

        on_create(rtm_ws, mock_ws_client)
        on_binary(rtm_ws, b"")

        state_connecting(rtm_ws)
        state_open(rtm_ws)
        state_closed(rtm_ws)
        state_closing(rtm_ws)
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
        on_text(rtm_ws, utf8(
            """{"type": "message", "text": "A message", "channel": "C0", "user": "U0", "ts": "12345.6789"}"""))

        # Send a message, and then we fake a reply to it.
        m_id1 = send_event(rtm_client, OutgoingMessageEvent("Hello", ChannelId("C0")))
        on_text(rtm_ws,
            utf8("""{"ok": true, "reply_to": $(m_id1), "text": "Hello", "channel": "C0", "ts": "12345.6789"}"""))

        # We don't expect any errors
        @fact mock_handler.errors --> isempty

        # Sleep because the channel needs to process the sent messages.
        sleep(0.02)
        # These are the events we expect.
        expect_event(mock_handler, HelloEvent())
        expect_event(mock_handler,
            MessageEvent("A message", ChannelId("C0"), UserId("U0"), EventTimestamp("12345.6789")))
        expect_channel_sent_event(mock_ws, Dict{Any,Any}(
            "id" => 1, "type" => "message", "text" => "Hello", "channel" => "C0"))
        expect_reply(mock_handler, m_id1,
            MessageAckEvent("Hello", Nullable(ChannelId("C0")), true, EventTimestamp("12345.6789")))
    end

    context("Throttling of events") do
        url = Requests.URI("wss://some/url/to/rtm")
        mock_ws = MockWSClient()
        mock_handler = MockRTMHandler()
        rtm_ws = nothing
        throttling_interval = 0.2
        function ws_client_factory(uri, handler)
            rtm_ws = handler
            mock_ws
        end

        rtm_client = rtm_connect(url, mock_handler;
            ws_client_factory=ws_client_factory,
            throttling_interval=throttling_interval)

        # Send messages and verify that they are throttled.
        n = 5
        for i = 1:n
            send_event(rtm_client, OutgoingMessageEvent("Hello", ChannelId("C0")))
        end

        # Wait for one throttling interval and verify that we haven't sent all messages yet.
        sleep(throttling_interval)
        @fact length(mock_ws.channel_sent) < n --> true

        # Sleep for the rest of the expected time and check that we have sent all messages.
        sleep(throttling_interval * (n - 2) + 0.05)
        @fact length(mock_ws.channel_sent) --> n

        # We don't expect any errors
        @fact mock_handler.errors --> isempty
    end
end