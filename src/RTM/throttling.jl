import Base.put!

export ThrottledChannel

immutable ThrottledChannel{T}
    throttle_chan::Channel{T}

    function ThrottledChannel{T}(chan::Channel{T}, interval::Float64; capacity::Int=32)
        throttle_chan = Channel{T}(capacity)

        @schedule begin
            for x in throttle_chan
                put!(chan, x)
                sleep(interval)
            end
        end

        new(throttle_chan)
    end
end

put!{T}(throttled::ThrottledChannel{T}, t::T) = put!(throttled.throttle_chan, t)