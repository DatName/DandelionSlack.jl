import Base: put!, take!
import WebSocketClient: AbstractWSClient, ClientLogicInput, send_text, get_channel, stop, ProxyCall,
                        handle

export ThrottledChannel,
       ThrottledWSClient

# ThrottledChannel acts like a Channel but waits `interval` seconds between sending
# messages.
# It works by having an intermediate channel which buffers messages and a coroutine that
# takes those messages and forwards them to the supplied channel.
immutable ThrottledChannel{T}
    throttle_chan::Channel{T}
    chan::Channel{T}

    function ThrottledChannel{T}(chan::Channel{T}, interval::Float64; capacity::Int=32)
        throttle_chan = Channel{T}(capacity)

        @schedule begin
            for x in throttle_chan
                put!(chan, x)
                sleep(interval)
            end
        end

        new(throttle_chan, chan)
    end
end

put!{T}(throttled::ThrottledChannel{T}, t::T) = put!(throttled.throttle_chan, t)
take!{T}(throttled::ThrottledChannel{T}) = take!(throttled.chan)


# ThrottledWSClient is a throttling proxy for an AbstractWSClient. It ensures that
# messages are not sent too often.
# Note: This really breaks the AbstractWSClient abstraction, because we require access to the
# channel that WSClient has. Without this type we would'nt need the `getchannel()` method.
# Also, we create SendTextFrames ourselves here, which also breaks the abstraction.
immutable ThrottledWSClient <: AbstractWSClient
    ws::AbstractWSClient
    chan::ThrottledChannel{ProxyCall}

    function ThrottledWSClient(ws::AbstractWSClient, interval::Float64; capacity::Int=32)
        chan = ThrottledChannel{ProxyCall}(get_channel(ws), interval; capacity=capacity)
        new(ws, chan)
    end
end

get_channel(ws::ThrottledWSClient) = ws.chan

# Close requests are not throttled. Note: This might lead to enqueued messages never being sent.
stop(ws::ThrottledWSClient) = stop(ws.ws)

send_text(ws::ThrottledWSClient, text::UTF8String) =
    put!(ws.chan, (handle, Any[WebSocketClient.SendTextFrame(text, true, OPCODE_TEXT)]))
