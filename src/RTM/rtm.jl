abstract RTMEvent

type RTMClient
    next_id::Int64

    RTMClient() = new(1)
end

function send_event(c::RTMClient, event::RTMEvent)
    this_id = c.next_id
    c.next_id += 1
    this_id
end