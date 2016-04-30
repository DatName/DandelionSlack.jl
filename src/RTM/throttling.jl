import Base: put!, take!

export ThrottledChannel

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