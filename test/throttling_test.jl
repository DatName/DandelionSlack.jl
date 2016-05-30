import DandelionWebSockets: AbstractWSClient, stop, send_text, send_binary

type MockThrottlingWSClient <: AbstractWSClient
    sent::Vector{UTF8String}
    bin_send::Vector{Vector{UInt8}}
    closed_called::Int

    function MockThrottlingWSClient()
        new(Vector{UTF8String}(), Vector{Vector{UInt8}}(), 0)
    end
end

function stop(c::MockThrottlingWSClient)
    c.closed_called += 1
end

send_text(c::MockThrottlingWSClient, s::UTF8String) = push!(c.sent, s)

function expect(c::MockThrottlingWSClient, s::UTF8String)
    if isempty(c.sent)
        error("Expected sent to have at least one element, with text '$s'")
    end
    actual = shift!(c.sent)
    @fact actual --> s
end

facts("Throttling") do
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
        @fact length(mock_ws.sent) < n --> true

        # After this sleep all events should have reached the WebSocket client
        sleep(throttle_time * n)
        @fact length(mock_ws.sent) --> n

        expect(mock_ws, utf8("Hello"))
        expect(mock_ws, utf8("Hello"))
        expect(mock_ws, utf8("Hello"))
        expect(mock_ws, utf8("Hello"))
        expect(mock_ws, utf8("Hello"))
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


