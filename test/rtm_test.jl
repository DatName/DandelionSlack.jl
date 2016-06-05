using DandelionWebSockets

import JSON
import Base.==
import DandelionSlack: on_event, on_reply, on_error, on_connect, on_disconnect,
                       EventTimestamp, RTMWebSocket, send_text, stop, RTMClient, makerequest,
                       wsconnect, HttpException
import DandelionWebSockets: @mock, @mockfunction, @expect, Throws, mock_match
import DandelionWebSockets: AbstractRetry, Retry, retry, reset, set_function

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

@mock MockWSClient AbstractWSClient
ws_client = MockWSClient()
@mockfunction(ws_client,
    send_text(::MockWSClient, ::UTF8String),
    stop(::MockWSClient),
    wsconnect(::MockWSClient, ::Requests.URI, ::WebSocketHandler))

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

post(::FakeRequests, uri::AbstractString; args...) = nothing

abstract AbstractMocker
@mock Mocker AbstractMocker
mocker = Mocker()
@mockfunction mocker makerequest(::Any, ::FakeRequests)

@mock MockRetry AbstractRetry
mock_retry = MockRetry()
@mockfunction mock_retry retry(::MockRetry) reset(::MockRetry) set_function(::MockRetry, ::Function)


token = Token("ABCDEF")
ok_status = Status(true, Nullable{UTF8String}(utf8("")), Nullable{UTF8String}(utf8("")))
# `fake_url` is what we get back from Slck. `expected_fake_url` is what the Slack URL needs to be
# converted to, in order to send it into Requests.
fake_url = utf8("ws://some/url")
expected_fake_url = Requests.URI("http://some/url")
fake_self = Self(UserId("U0"), SlackName("User 0"), 123, utf8(""))
fake_team = Team(TeamId("T0"), SlackName("Team 0"), utf8(""), utf8(""))
fake_rtm_start_response = RtmStartResponse(fake_url, fake_self, fake_team,
    [], [], [], Nullable{DandelionSlack.Mpim}(), [], [])

#
# Matching JSON
#

immutable JSONMatcher <: AbstractMatcher
    object::Dict{Any, Any}
end

mock_match(m::JSONMatcher, v::AbstractString) = m.object == JSON.parse(v)

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

    context("Propagate events from WebSocket to RTM") do
        rtm_ws = RTMWebSocket(mock_retry)
        attach(rtm_ws, mock_handler)

        @expect mock_handler on_event(mock_handler,
            MessageEvent(utf8("Hello"), ChannelId(utf8("C0")), UserId("U0"), EventTimestamp("123")))

        on_text(rtm_ws, utf8("""{"type": "message", "channel": "C0",
            "text": "Hello", "user": "U0", "ts": "123"}"""))

        check(mock_handler)
        check(mock_retry)
    end

    context("Message ack event") do
        rtm_ws = RTMWebSocket(mock_retry)
        attach(rtm_ws, mock_handler)

        @expect mock_handler on_reply(mock_handler, 1,
            MessageAckEvent(utf8("Hello"), Nullable(ChannelId("C0")), true, EventTimestamp("123")))

        on_text(rtm_ws,
            utf8("""{"reply_to": 1, "ok": true, "text": "Hello", "channel": "C0", "ts": "123"}"""))

        check(mock_handler)
        check(mock_retry)
    end

    context("Missing type key and not message ack") do
        rtm_ws = RTMWebSocket(mock_retry)
        attach(rtm_ws, mock_handler)

        text = utf8("""{"reply_to": 1}""")
        @expect mock_handler on_error(mock_handler, MissingTypeError(text))

        on_text(rtm_ws, text)

        check(mock_handler)
        check(mock_retry)
    end


    context("Invalid JSON") do
        rtm_ws = RTMWebSocket(mock_retry)
        attach(rtm_ws, mock_handler)

        text = utf8("""{"reply_to" foobarbaz""")

        @expect mock_handler on_error(mock_handler, InvalidJSONError(text))

        on_text(rtm_ws, text)

        check(mock_handler)
        check(mock_retry)
    end

    context("Unknown message type") do
        rtm_ws = RTMWebSocket(mock_retry)
        attach(rtm_ws, mock_handler)

        text = utf8("""{"type": "nosuchtype"}""")

        @expect mock_handler on_error(mock_handler, UnknownEventTypeError(text, utf8("nosuchtype")))

        on_text(rtm_ws, text)

        check(mock_handler)
        check(mock_retry)
    end

    context("Missing required field") do
        rtm_ws = RTMWebSocket(mock_retry)
        attach(rtm_ws, mock_handler)

        # No "text" field.
        text = utf8("""{"type": "message", "channel": "C0", "user": "U0", "ts": "123"}""")

        @expect mock_handler on_error(mock_handler, DeserializationError(utf8("text"), text, MessageEvent))

        on_text(rtm_ws, text)

        check(mock_handler)
        check(mock_retry)
    end

    context("Error event from Slack") do
        rtm_ws = RTMWebSocket(mock_retry)
        attach(rtm_ws, mock_handler)

        @expect mock_handler on_event(mock_handler, ErrorEvent(RTMError(1, "Reason")))

        on_text(rtm_ws,
            utf8("""{"type": "error", "error": {"code": 1, "msg": "Reason"}}"""))

        check(mock_retry)
        check(mock_handler)
    end

    context("Retry connection on WebSocket close") do
        rtm_ws = RTMWebSocket(mock_retry)
        attach(rtm_ws, mock_handler)

        @expect mock_handler on_disconnect(mock_handler)
        @expect mock_retry retry(mock_retry)

        state_closed(rtm_ws)

        check(mock_handler)
        check(mock_retry)
    end

    context("Successful connection") do
        rtm_ws = RTMWebSocket(mock_retry)
        attach(rtm_ws, mock_handler)

        @expect mock_handler on_connect(mock_handler)
        @expect mock_retry reset(mock_retry)

        state_open(rtm_ws)

        check(mock_handler)
        check(mock_retry)
    end

    # This only tests that the callback functions exist, not that they actually do anything.
    # This is mostly for coverage.
    context("Existence of the rest of WebSocketHandler interface functions") do
        rtm_ws = RTMWebSocket(mock_retry)
        attach(rtm_ws, mock_handler)

        on_binary(rtm_ws, b"")
        state_connecting(rtm_ws)
        state_closing(rtm_ws)

        check(mock_handler)
        check(mock_retry)
    end
end

facts("RTMClient") do
    context("Send and receive events") do
        @expect mock_retry set_function(mock_retry, TypeMatcher(Function))

        rtm_client = RTMClient(token;
                               connection_retry=mock_retry, ws_client_factory=x -> ws_client)
        attach(rtm_client, mock_handler)

        # `fake_rtm_start_response` uses `fake_url` as the URL we should connect to.
        @expect mocker makerequest(TypeMatcher(Any), fake_requests) (ok_status, fake_rtm_start_response)
        @expect ws_client wsconnect(ws_client, Requests.URI(fake_url), rtm_client.rtm_ws)
        rtm_connect(rtm_client; requests=fake_requests)

        # We will send two events from server to client, a HelloEvent and a message "A message".
        @expect mock_handler on_event(mock_handler, HelloEvent())
        @expect mock_handler on_event(mock_handler,
            MessageEvent("A message", ChannelId("C0"), UserId("U0"), EventTimestamp("12345.6789")))

        first_id = 1

        # ... then send one event from client to server, and then send the reply to that message.
        @expect ws_client send_text(ws_client, JSONMatcher(Dict{Any, Any}(
            "id" => first_id, "type" => "message", "text" => "Hello", "channel" => "C0")))
        @expect mock_handler on_reply(mock_handler, first_id,
            MessageAckEvent("Hello", Nullable(ChannelId("C0")), true, EventTimestamp("12345.6789")))

        # These are fake events from the WebSocket
        on_text(rtm_client.rtm_ws, utf8("""{"type": "hello"}"""))
        on_text(rtm_client.rtm_ws, utf8(
            """{"type": "message", "text": "A message", "channel": "C0", "user": "U0", "ts": "12345.6789"}"""))

        # Send a message, and then we fake a reply to it.
        m_id1 = send_event(rtm_client, OutgoingMessageEvent("Hello", ChannelId("C0")))
        on_text(rtm_client.rtm_ws,
            utf8("""{"ok": true, "reply_to": $(first_id), "text": "Hello", "channel": "C0", "ts": "12345.6789"}"""))


        check(ws_client)
        check(mocker)
        check(mock_handler)
        check(mock_retry)
    end

    context("Connection failed due to exception") do
        @expect mock_retry set_function(mock_retry, TypeMatcher(Function))

        rtm_client = RTMClient(token;
                               connection_retry=mock_retry,
                               ws_client_factory=x -> ws_client)
        attach(rtm_client, mock_handler)

        # `fake_rtm_start_response` uses `fake_url` as the URL we should connect to.
        @expect mocker makerequest(TypeMatcher(Any), fake_requests) Throws(HttpException())
        @expect mock_handler on_disconnect(mock_handler)
        @expect mock_retry retry(mock_retry)
        rtm_connect(rtm_client; requests=fake_requests)

        check(ws_client)
        check(mocker)
        check(mock_handler)
        check(mock_retry)
    end

    context("Set retry function to rtm_connect") do
        @expect mock_retry set_function(mock_retry, TypeMatcher(Function))

        rtm_client = RTMClient(token;
                               connection_retry=mock_retry,
                               ws_client_factory=x -> ws_client)
        attach(rtm_client, mock_handler)

        check(ws_client)
        check(mocker)
        check(mock_handler)
        check(mock_retry)
    end

    context("Sending events") do
        @expect mock_retry set_function(mock_retry, TypeMatcher(Function))

        rtm = DandelionSlack.RTMClient(token;
                                       connection_retry=mock_retry,
                                       ws_client_factory=x -> ws_client)
        attach(rtm, mock_handler)

        @expect ws_client send_text(ws_client, JSONMatcher(
            Dict{Any,Any}("id" => 1, "value" => test_event_1.value)))
        @expect ws_client send_text(ws_client, JSONMatcher(
            Dict{Any,Any}("id" => 2, "value" => test_event_2.value)))

        DandelionSlack.send_event(rtm, test_event_1)
        DandelionSlack.send_event(rtm, test_event_2)

        check(mock_retry)
    end

    context("Send close on user request") do
        @expect mock_retry set_function(mock_retry, TypeMatcher(Function))

        rtm = DandelionSlack.RTMClient(token;
                                       connection_retry=mock_retry,
                                       ws_client_factory=x -> ws_client)
        attach(rtm, mock_handler)

        @expect ws_client stop(ws_client)
        close(rtm)

        check(mock_retry)
    end

    context("Increasing message id") do
        @expect mock_retry set_function(mock_retry, TypeMatcher(Function))

        rtm = DandelionSlack.RTMClient(token;
                                       connection_retry=mock_retry,
                                       ws_client_factory=x -> ws_client)
        attach(rtm, mock_handler)

        @expect ws_client send_text(ws_client, TypeMatcher(UTF8String))
        @expect ws_client send_text(ws_client, TypeMatcher(UTF8String))
        @expect ws_client send_text(ws_client, TypeMatcher(UTF8String))

        message_id_1 = DandelionSlack.send_event(rtm, FakeEvent())
        message_id_2 = DandelionSlack.send_event(rtm, FakeEvent())
        message_id_3 = DandelionSlack.send_event(rtm, FakeEvent())

        @fact message_id_1 < message_id_2 < message_id_3 --> true

        check(mock_retry)
    end

    context("Throttling of events") do
        throttling = 0.2

        throttled_client = ThrottledWSClient(ws_client, throttling)

        @expect mock_retry set_function(mock_retry, TypeMatcher(Function))

        rtm_client = RTMClient(token;
                               connection_retry=mock_retry,
                               ws_client_factory=x -> throttled_client)
        attach(rtm_client, mock_handler)

        # `fake_rtm_start_response` uses `fake_url` as the URL we should connect to.
        @expect mocker makerequest(TypeMatcher(Any), fake_requests) (ok_status, fake_rtm_start_response)
        @expect ws_client wsconnect(ws_client, Requests.URI(fake_url), rtm_client.rtm_ws)
        rtm_connect(rtm_client; requests=fake_requests)

        # Send messages and verify that they are throttled.
        @expect ws_client send_text(ws_client, TypeMatcher(UTF8String))

        n = 5
        for i = 1:n
            send_event(rtm_client, OutgoingMessageEvent("Hello", ChannelId("C0")))
        end
        sleep(0.01)
        check(ws_client)

        @expect ws_client send_text(ws_client, TypeMatcher(UTF8String))
        # Wait for one throttling interval and verify that we haven't sent all messages yet.
        sleep(throttling)
        check(ws_client)

        @expect ws_client send_text(ws_client, TypeMatcher(UTF8String))
        @expect ws_client send_text(ws_client, TypeMatcher(UTF8String))
        @expect ws_client send_text(ws_client, TypeMatcher(UTF8String))
        # Sleep for the rest of the expected time and check that we have sent all messages.
        sleep(throttling * (n - 2) + 0.05)

        check(ws_client)
        check(mocker)
        check(mock_handler)
        check(mock_retry)
    end
end