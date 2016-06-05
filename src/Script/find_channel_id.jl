#!/usr/bin/env julia

using DandelionSlack
using DandelionSlack.Util

using DocOpt

doc = """Find the Slack channel id given a channel name.

Usage:
    find_channel_id.jl <team> <name>
    find_channel_id.jl --version

Options:
    --version   Show version
"""

arguments = docopt(doc, version=v"0.0.1")

team = arguments["<team>"]
name = arguments["<name>"]

token = find_token(team)

channels_list = ChannelsList(token, Nullable{Int64}())
try
    status, response = makerequest(channels_list, real_requests)
    channel_index = findfirst(c -> c.name == name, response.channels)
    if channel_index == 0
        println("No channel named $(name) in team $(team)")
    else
        channel = response.channels[channel_index]
        println("Channel id for $(name) in team $(team): $(channel.id)")
    end
catch ex
    dump(ex)
end
