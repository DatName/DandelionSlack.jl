using DandelionWebSockets

import JSON
import Base.==
import DandelionSlack: on_event, on_reply, on_error, on_connect, on_disconnect,
                       EventTimestamp, RTMWebSocket
import DandelionWebSockets: @mock, @mockfunction, @expect, Throws
import DandelionWebSockets: AbstractRetry, Retry, retry, reset

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
    closed_called::Int

    function MockWSClient()
        new([], 0)
    end
end

function DandelionWebSockets.stop(c::MockWSClient)
    c.closed_called += 1
end
DandelionWebSockets.send_text(c::MockWSClient, s::UTF8String) = push!(c.sent, JSON.parse(s))

function expect_sent_event(c::MockWSClient, expected::Dict{Any,Any})
    @fact isempty(c.sent) --> false
    if isempty(c.sent)
        error("No sent event corresponding to expected $expected")
    end

    parsed = shift!(c.sent)
    @fact parsed --> expected
end

expect_close(c::MockWSClient; no_of_closes::Int=1) = @fact c.closed_called --> no_of_closes

#
# A mock RTMHandler to test that RTMWebSocket propagates messages correctly.
#

@mock MockRTMHandler RTMHandler
mock_handler = MockRTMHandler()
@mockfunction(mock_handler,
    on_reply(::MockRTMHandler, ::Int64, ::DandelionSlack.Event),
    on_event(::MockRTMHandler, ::DandelionSlack.Event),
    on_error(::MockRTMHandler, e::EventError),
    on_disconnect(::MockRTMHandler),
    on_connect(::MockRTMHandler))

#
# Fake requests and mocking the makerequests function.
#

immutable FakeRequests <: AbstractHttp end
fake_requests = FakeRequests()

abstract AbstractMocker
@mock Mocker AbstractMocker
mocker = Mocker()
@mockfunction mocker makerequest(::Any, ::FakeRequests)

@mock MockRetry AbstractRetry
mock_retry = MockRetry()
@mockfunction mock_retry retry(::MockRetry) reset(::MockRetry)

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
        rtm_ws = RTMWebSocket(mock_handler, mock_retry)

        @expect mock_handler on_event(mock_handler,
            MessageEvent(utf8("Hello"), ChannelId(utf8("C0")), UserId("U0"), EventTimestamp("123")))

        on_text(rtm_ws, utf8("""{"type": "message", "channel": "C0",
            "text": "Hello", "user": "U0", "ts": "123"}"""))

        check(mock_handler)
    end

    context("Message ack event") do
        rtm_ws = RTMWebSocket(mock_handler, mock_retry)

        @expect mock_handler on_reply(mock_handler, 1,
            MessageAckEvent(utf8("Hello"), Nullable(ChannelId("C0")), true, EventTimestamp("123")))

        on_text(rtm_ws,
            utf8("""{"reply_to": 1, "ok": true, "text": "Hello", "channel": "C0", "ts": "123"}"""))

        check(mock_handler)
    end

    context("Missing type key and not message ack") do
        rtm_ws = RTMWebSocket(mock_handler, mock_retry)

        text = utf8("""{"reply_to": 1}""")
        @expect mock_handler on_error(mock_handler, MissingTypeError(text))

        on_text(rtm_ws, text)

        check(mock_handler)
    end


    context("Invalid JSON") do
        rtm_ws = RTMWebSocket(mock_handler, mock_retry)
        text = utf8("""{"reply_to" foobarbaz""")

        @expect mock_handler on_error(mock_handler, InvalidJSONError(text))

        on_text(rtm_ws, text)

        check(mock_handler)
    end

    context("Unknown message type") do
        rtm_ws = RTMWebSocket(mock_handler, mock_retry)
        text = utf8("""{"type": "nosuchtype"}""")

        @expect mock_handler on_error(mock_handler, UnknownEventTypeError(text, utf8("nosuchtype")))

        on_text(rtm_ws, text)

        check(mock_handler)
    end

    context("Missing required field") do
        rtm_ws = RTMWebSocket(mock_handler, mock_retry)
        # No "text" field.
        text = utf8("""{"type": "message", "channel": "C0", "user": "U0", "ts": "123"}""")

        @expect mock_handler on_error(mock_handler, DeserializationError(utf8("text"), text, MessageEvent))

        on_text(rtm_ws, text)

        check(mock_handler)
    end

    context("Error event from Slack") do
        rtm_ws = RTMWebSocket(mock_handler, mock_retry)

        @expect mock_handler on_event(mock_handler, ErrorEvent(RTMError(1, "Reason")))

        on_text(rtm_ws,
            utf8("""{"type": "error", "error": {"code": 1, "msg": "Reason"}}"""))

        check(mock_handler)
    end

    context("Retry connection on WebSocket close") do
        rtm_ws = RTMWebSocket(mock_handler, mock_retry)

        @expect mock_handler on_disconnect(mock_handler)
        @expect mock_retry retry(mock_retry)

        state_closed(rtm_ws)

        check(mock_handler)
        check(mock_retry)
    end

    context("Successful connection") do
        rtm_ws = RTMWebSocket(mock_handler, mock_retry)

        @expect mock_handler on_connect(mock_handler)
        @expect mock_retry reset(mock_retry)

        state_open(rtm_ws)

        check(mock_handler)
        check(mock_retry)
    end

    # This only tests that the callback functions exist, not that they actually do anything.
    # This is mostly for coverage.
    context("Existence of the rest of WebSocketHandler interface functions") do
        rtm_ws = RTMWebSocket(mock_handler, mock_retry)

        on_binary(rtm_ws, b"")
        state_connecting(rtm_ws)
        state_closing(rtm_ws)
    end
end

facts("RTM integration") do
    context("Send and receive events") do
        url = Requests.URI("wss://some/url/to/rtm")
        mock_ws = MockWSClient()
        mock_handler = MockRTMHandler()
        rtm_ws = nothing
        function ws_client_factory(uri, handler)
            actual_url = url
            rtm_ws = handler
            mock_ws
        end

        rtm_client = rtm_connect(mock_handler; requests=fake_requests)

        # TODO: expect makerequest(TypeMatcher(RtmStart), fake_requests)
        #       Returns an OK reply.

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
        expect_sent_event(mock_ws, Dict{Any,Any}(
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
        @fact length(mock_ws.sent) < n --> true

        # Sleep for the rest of the expected time and check that we have sent all messages.
        sleep(throttling_interval * (n - 2) + 0.05)
        @fact length(mock_ws.sent) --> n

        # We don't expect any errors
        @fact mock_handler.errors --> isempty
    end
end