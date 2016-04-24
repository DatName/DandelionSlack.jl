immutable FakeEvent <: DandelionSlack.RTMEvent end

facts("RTM events") do
    context("Increasing message id") do
        rtm = DandelionSlack.RTMClient()

        message_id_1 = DandelionSlack.send_event(rtm, FakeEvent())
        message_id_2 = DandelionSlack.send_event(rtm, FakeEvent())
        message_id_3 = DandelionSlack.send_event(rtm, FakeEvent())

        @fact message_id_1 < message_id_2 < message_id_3 --> true
    end
end