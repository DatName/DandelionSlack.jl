module DandelionSlack

include("WebApi/json_deserialize.jl")
include("WebApi/helpers.jl")
include("WebApi/newtype.jl")
include("WebApi/auxiliary_types.jl")
include("WebApi/types.jl")
include("WebApi/methods.jl")
include("WebApi/rtm.jl")
include("WebApi/channels.jl")
include("WebApi/requests.jl")

include("RTM/events.jl")
include("RTM/register.jl")
include("RTM/misc_events.jl")
include("RTM/messages.jl")

include("RTM/rtm.jl")

include("Util/util.jl")

end # module
