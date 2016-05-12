import WebSocketClient: ProxyCall

type MockThrottlingWSClient <: AbstractWSClient
    sent::Vector{UTF8String}
    channel_sent::Vector{ProxyCall}
    closed_called::Int
    chan::Channel{ProxyCall}

    function MockThrottlingWSClient()
        channel_sent = Vector{ProxyCall}()
        chan = Channel{ProxyCall}(32)
        @schedule begin
            for m in chan
                push!(channel_sent, m)
            end
        end
        new([], channel_sent, 0, chan)
    end
end

function WebSocketClient.stop(c::MockThrottlingWSClient)
    c.closed_called += 1
    close(c.chan)
end

WebSocketClient.send_text(c::MockThrottlingWSClient, s::UTF8String) = push!(c.sent, s)
WebSocketClient.get_channel(c::MockThrottlingWSClient) = c.chan

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

    context("ThrottledWSClient") do
        throttle_time = 0.05
        mock_ws = MockThrottlingWSClient()
        throttled_ws = ThrottledWSClient(mock_ws, throttle_time)

        n = 5
        for i in 1:n
            send_text(throttled_ws, utf8("Hello"))
        end

        # Sleep a short amount of time
        sleep(0.1)
        # All events should not have reached the mock WebSocket client.
        @fact length(mock_ws.channel_sent) < n --> true

        # After this sleep all events should have reached the WebSocket client
        sleep(throttle_time * n)
        @fact length(mock_ws.channel_sent) --> n
    end

    context("ThrottledWSClient does not throttle close") do
        throttle_time = 0.05
        mock_ws = MockThrottlingWSClient()
        throttled_ws = ThrottledWSClient(mock_ws, throttle_time)

        n = 5
        for i in 1:n
            stop(throttled_ws)
        end

        # Sleep a short amount of time, less than what it would have taken had all requests been
        # throttled.
        sleep(throttle_time)
        # Check that all close requests have reached the mock WSClient.
        @fact mock_ws.closed_called --> n
    end
end


