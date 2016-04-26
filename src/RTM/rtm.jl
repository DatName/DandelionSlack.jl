export RTMHandler

using WebSocketClient
import JSON

#
# RTMEvent is an abstract type for all messages sent and received as events via Slack RTM.
#

abstract RTMEvent

serialize(event::RTMEvent) = error("serialize not implemented for $(event)")

#
# RTMClient is an object for sending events to Slack.
#

type RTMClient
    client::AbstractWSClient
    next_id::Int64

    RTMClient(client::AbstractWSClient) = new(client, 1)
end

function send_event(c::RTMClient, event::RTMEvent)
    this_id = c.next_id
    c.next_id += 1

    dict = serialize(event)
    dict["id"] = this_id
    text = utf8(JSON.json(dict))
    send_text(c.client, text)

    this_id
end

close(c::RTMClient) = stop(c.client)

#
# RTMHandler defines an interface for handling RTM events.
#

abstract RTMHandler

on_event(h::RTMHandler, id::Int64, event::RTMEvent) =
    error("on_event not implemented for $(h) and/or $(event)")

#
# RTMWebSocketHandler takes events from a WebSocket connection and converts to RTM events.
#

type RTMWebSocket <: WebSocketHandler
    handler::RTMHandler
end

function WebSocketClient.on_text(rtm::RTMWebSocket, text::UTF8String)
    dict = JSON.parse(text)
    # TODO: Handle error when required fields like type is missing
    event_type = find_event(dict["type"])
    event = deserialize(event_type, dict)

    if haskey(dict, "id")
        message_id = dict["id"]
        on_event(rtm.handler, message_id, event)
    else
        on_event(rtm.handler, event)
    end
end