facts("Throttling") do
    context("Throttle three messages") do
        throttle_time = 0.1
        chan = Channel{Int64}(32)
        # Add a bit of margin to the throttle_time to make the test reliable.
        throttled_chan = ThrottledChannel{Int64}(chan, throttle_time + 0.005)

        # Verify that it takes very little time to send three messages on the normal channel
        put!(chan, 1)
        put!(chan, 2)
        put!(chan, 3)

        tic()
        @fact take!(chan) --> 1
        @fact take!(chan) --> 2
        @fact take!(chan) --> 3
        @fact toc() < throttle_time --> true

        # Verify that three messages take more than 2*throttle_time to complete. The first message
        # is sent right away at time 0*throttle_time, the second at 1*throttle_time, and the third
        # at 2*throttle_time.
        put!(throttled_chan, 1)
        put!(throttled_chan, 2)
        put!(throttled_chan, 3)

        tic()
        @fact take!(throttled_chan) --> 1
        @fact take!(throttled_chan) --> 2
        @fact take!(throttled_chan) --> 3
        @fact toc() >= 2*throttle_time --> true
    end
end


