export RTMHandler,
       rtm_connect,
       send_event

using WebSocketClient
import WebSocketClient: on_text, on_close, on_closing, on_create
import JSON

#
# RTMHandler defines an interface for handling RTM events.
#

abstract RTMHandler

on_reply(h::RTMHandler, id::Int64, event::Event) =
    error("on_reply not implemented for $(h) and/or $(event)")

on_event(h::RTMHandler, event::Event) =
    error("on_event not implemented for $(h) and/or $(event)")

# on error is called when there is a problem with receiving the message, such as invalid JSON.
# This is not an error sent by Slack, but an error caught in this code.
on_error(h::RTMHandler, reason::Symbol, text::UTF8String) =
    error("on_error not implemented for $(h)")

#
# RTMWebSocketHandler takes events from a WebSocket connection and converts to RTM events.
#

type RTMWebSocket <: WebSocketHandler
    handler::RTMHandler
end

function on_text(rtm::RTMWebSocket, text::UTF8String)
    dict::Dict{AbstractString, Any} = Dict()
    try
        dict = JSON.parse(text)
    catch ex
        if isa(ex, ErrorException)
            on_error(rtm.handler, :invalid_json, text)
            return
        end
        rethrow(ex)
    end

    if !haskey(dict, "type")
        # Special case: A message ack does not have a type property, but is instead identified by
        # having a text and a reply_to property.
        # We fake a type "message_ack" for it, so it's handled by the same code as everything else.
        if haskey(dict, "text") && haskey(dict, "reply_to")
            dict["type"] = utf8("message_ack")
        else
            on_error(rtm.handler, :missing_type, text)
            return
        end
    end

    event_type = find_event(dict["type"])
    if event_type == nothing
        on_error(rtm.handler, :unknown_message_type, text)
        return
    end

    event = deserialize(event_type, dict)

    if haskey(dict, "reply_to")
        message_id = dict["reply_to"]
        on_reply(rtm.handler, message_id, event)
    else
        on_event(rtm.handler, event)
    end
end

# TODO: Implement these WebSocketHandler callbacks
on_close(t::RTMWebSocket) = println("RTMWebSocket.on_close")
on_create(t::RTMWebSocket, ::AbstractWSClient) = println("RTMWebSocket.on_create")
on_closing(t::RTMWebSocket) = println("RTMWebSocket.on_closing")

#
# RTMClient is an object for sending events to Slack.
#

abstract AbstractRTMClient

type RTMClient <: AbstractRTMClient
    client::AbstractWSClient
    next_id::Int64

    RTMClient(client::AbstractWSClient) = new(client, 1)
end

function send_event(c::RTMClient, event::OutgoingEvent)
    this_id = c.next_id
    c.next_id += 1

    dict = serialize(event)
    dict["id"] = this_id
    text = utf8(JSON.json(dict))
    send_text(c.client, text)

    this_id
end

close(c::RTMClient) = stop(c.client)

function rtm_connect(uri::Requests.URI, handler::RTMHandler;
        ws_client_factory=WebSocketClient.WSClient,
        throttling_interval::Float64=1.0)

    rtm_ws = RTMWebSocket(handler)
    ws_client = ws_client_factory(uri, rtm_ws)
    throttled_ws_client = ThrottledWSClient(ws_client, throttling_interval)

    RTMClient(throttled_ws_client)
end