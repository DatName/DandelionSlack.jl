export RTMHandler,
       rtm_connect,
       send_event

using DandelionWebSockets
import DandelionWebSockets: on_text, on_binary,
                            state_connecting, state_open, state_closing, state_closed,
                            AbstractWSClient
import JSON

#
# RTMHandler defines an interface for handling RTM events.
#

abstract RTMHandler

on_reply(h::RTMHandler, id::Int, event::Event) =
    error("on_reply not implemented for $(h) and/or $(event)")

on_event(h::RTMHandler, event::Event) =
    error("on_event not implemented for $(h) and/or $(event)")

# on error is called when there is a problem with receiving the message, such as invalid JSON.
# This is not an error sent by Slack, but an error caught in this code.
on_error(h::RTMHandler, e::EventError) =
    error("on_error not implemented for $(h) or $e")

#
# RTMWebSocketHandler takes events from a WebSocket connection and converts to RTM events.
#

type RTMWebSocket <: WebSocketHandler
    handler::RTMHandler
    connection_retry::AbstractRetry
end

function on_text(rtm::RTMWebSocket, text::UTF8String)
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

# TODO: Implement these WebSocketHandler callbacks
on_binary(::RTMWebSocket, ::Vector{UInt8}) = nothing
state_connecting(::RTMWebSocket) = nothing
# TODO: Reset connection retry.
state_open(::RTMWebSocket) = nothing
# TODO: Ensure that the connection is retried.
state_closed(t::RTMWebSocket) = nothing
state_closing(t::RTMWebSocket) = nothing

#
# RTMClient is an object for sending events to Slack.
#

abstract AbstractRTMClient

type RTMClient <: AbstractRTMClient
    client::AbstractWSClient
    next_id::Int64

    # TODO: Keep an RTMWebSocket here?

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

function rtm_connect(client::RTMClient)

end