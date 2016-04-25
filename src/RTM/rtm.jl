using WebSocketClient
import JSON

abstract RTMEvent

serialize(event::RTMEvent) = error("serialize not implemented for $(event)")

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