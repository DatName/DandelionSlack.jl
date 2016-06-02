import Base: put!, take!, close
import DandelionWebSockets: AbstractWSClient, ClientLogicInput, send_text, stop,
                        handle

export ThrottledWSClient

typealias WSCall Tuple{Function, Vector{Any}}

# ThrottledWSClient is a throttling proxy for an AbstractWSClient. It ensures that
# messages are not sent too often.
immutable ThrottledWSClient <: AbstractWSClient
    ws::AbstractWSClient
    chan::Channel{WSCall}

    function ThrottledWSClient(ws::AbstractWSClient, interval::Float64; capacity::Int=32)
        chan = Channel{WSCall}(capacity)

        @schedule begin
            for (f, args) in chan
                f(args...)
                sleep(interval)
            end
        end

        new(ws, chan)
    end
end

# Close requests are not throttled, because this doesn't send a message over to Slack.
# Note: This might lead to enqueued messages never being sent.
function stop(ws::ThrottledWSClient)
    stop(ws.ws)
    close(ws.chan)
end

send_text(ws::ThrottledWSClient, text::UTF8String) = put!(ws.chan, (send_text, [ws.ws, text]))
