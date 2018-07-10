export RTMHandler,
       rtm_connect,
       send_event,
       RTMClient,
       on_reply,
       on_event,
       on_error,
       on_disconnect,
       on_connect,
       attach

using DandelionWebSockets
import DandelionWebSockets: on_text, on_binary,
                            state_connecting, state_open, state_closing, state_closed,
                            AbstractWSClient
import JSON

#
# RTMHandler defines an interface for handling RTM events.
#

abstract type RTMHandler end

on_reply(h::RTMHandler, id::Int, event::Event) =
    error("on_reply not implemented for $(h) and/or $(event)")

on_event(h::RTMHandler, event::Event) =
    error("on_event not implemented for $(h) and/or $(event)")

# on error is called when there is a problem with receiving the message, such as invalid JSON.
# This is not an error sent by Slack, but an error caught in this code.
on_error(h::RTMHandler, e::EventError) =
    error("on_error not implemented for $(h) or $e")

on_disconnect(h::RTMHandler) = error("on_disconnect not implemented for $(h)")
on_connect(h::RTMHandler) = error("on_connect not implemented for $(h)")

#
#
#
immutable UnsetRTMHandler <: RTMHandler end

on_reply(h::UnsetRTMHandler, id::Int, event::Event) =
    error("No RTM handler set! Call attach(::RTMClient, ::RTMHandler) before connect")

on_event(h::UnsetRTMHandler, event::Event) =
    error("No RTM handler set! Call attach(::RTMClient, ::RTMHandler) before connect")

# on error is called when there is a problem with receiving the message, such as invalid JSON.
# This is not an error sent by Slack, but an error caught in this code.
on_error(h::UnsetRTMHandler, e::EventError) =
    error("No RTM handler set! Call attach(::RTMClient, ::RTMHandler) before connect")

on_disconnect(h::UnsetRTMHandler) =
    error("No RTM handler set! Call attach(::RTMClient, ::RTMHandler) before connect")

on_connect(h::UnsetRTMHandler) =
    error("No RTM handler set! Call attach(::RTMClient, ::RTMHandler) before connect")

#
# RTMWebSocketHandler takes events from a WebSocket connection and converts to RTM events.
#

mutable struct RTMWebSocket <: WebSocketHandler
    handler::RTMHandler
    connection_retry::AbstractRetry

    RTMWebSocket(retry::AbstractRetry) = new(UnsetRTMHandler(), retry)
end

function on_text(rtm::RTMWebSocket, text::String)
    dict::Dict{AbstractString, Any} = Dict()
    try
        dict = JSON.parse(text)
    catch ex
        if isa(ex, ErrorException)
            on_error(rtm.handler, InvalidJSONError(text))
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
            on_error(rtm.handler, MissingTypeError(text))
            return
        end
    end

    event_type = find_event(dict["type"])
    if event_type == nothing
        on_error(rtm.handler, UnknownEventTypeError(text, dict["type"]))
        return
    end

    event = nothing
    try
        event = deserialize(event_type, dict)
    catch ex
        if isa(ex, KeyError)
            on_error(rtm.handler, DeserializationError(ex.key, text, event_type))
            return
        else
            rethrow(ex)
        end
    end

    if haskey(dict, "reply_to")
        message_id = dict["reply_to"]
        on_reply(rtm.handler, message_id, event)
    else
        on_event(rtm.handler, event)
    end
end

function state_open(rtm::RTMWebSocket)
    on_connect(rtm.handler)
    reset(rtm.connection_retry)
end

function state_closed(rtm::RTMWebSocket)
    on_disconnect(rtm.handler)
    retry(rtm.connection_retry)
end

# Implement a warning here, as Slack shouldn't send binary messages.
on_binary(::RTMWebSocket, ::Vector{UInt8}) = nothing
state_connecting(::RTMWebSocket) = nothing
state_closing(t::RTMWebSocket) = nothing

attach(t::RTMWebSocket, handler::RTMHandler) = t.handler = handler

#
# RTMClient is an object for sending events to Slack.
#

abstract type AbstractRTMClient end

default_backoff = RandomizedBackoff(Backoff(5.0, 200.0), MersenneTwister(0), 3.0)

throttled_client_factory = handler -> ThrottledWSClient(WSClient(), 1.0)

mutable struct RTMClient <: AbstractRTMClient
    ws_client::AbstractWSClient
    next_id::Int64
    rtm_ws::RTMWebSocket
    token::Token

    function RTMClient(token::Token;
                       connection_retry::AbstractRetry=Retry(default_backoff, x -> nothing),
                       ws_client_factory=throttled_client_factory)
        rtm_ws = RTMWebSocket(connection_retry)
        ws_client = ws_client_factory(rtm_ws)
        c = new(ws_client, 1, rtm_ws, token)
        set_function(connection_retry, () -> rtm_connect(c))
        c
    end
end

show(io::IO, c::RTMClient) = show(io, "RTMClient($(c.next_id), $(c.token), $(c.rtm_ws))")

function send_event(c::RTMClient, event::OutgoingEvent)
    this_id = c.next_id
    c.next_id += 1

    dict = serialize(event)
    dict["id"] = this_id
    text = utf8(JSON.json(dict))
    send_text(c.ws_client, text)

    this_id
end

close(c::RTMClient) = stop(c.ws_client)
attach(c::RTMClient, handler::RTMHandler) = attach(c.rtm_ws, handler)

function rtm_connect(client::RTMClient;
                     requests=real_requests)
    try
        status, response = makerequest(
            RtmStart(client.token, Nullable(), Nullable(), Nullable()), requests)
        wsconnect(client.ws_client, Requests.URI(response.url), client.rtm_ws)
    catch ex
        println("Exception when connecting: $ex")
        state_closed(client.rtm_ws)
    end
end
