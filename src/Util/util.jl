# Utilities for reading access tokens from files.
#
# When using a script you can specify the team, and the appropriate token will be found.
#
# Token are stored in a ".dandelion" in your home directory.

module Util

import DandelionSlack

export
    write_token,
    find_token

token_dir = "~/.dandelion"

token_file(team::AbstractString) = joinpath(expanduser(token_dir), "$(team).token")
find_token(team::AbstractString) = DandelionSlack.Token(utf8(readall(token_file(team))))

ensure_token_dir() = mkpath(expanduser(token_dir))

function write_token(team::AbstractString, token::AbstractString)
    ensure_token_dir()
    open(s -> write(s, token), token_file(team), "a")
end


end