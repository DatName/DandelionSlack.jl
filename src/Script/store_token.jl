#!/usr/bin/env julia

using DandelionSlack.Util
using DocOpt

doc = """Store a Julia token in the token directory.

Usage:
    store_token.jl <team> <token>
    store_token.jl --version

Options:
    --version   Show version.
"""

arguments = docopt(doc, version=v"0.0.1")

team = arguments["<team>"]
token = arguments["<token>"]

write_token(team, token)