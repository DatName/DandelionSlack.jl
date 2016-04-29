event_register = Dict{AbstractString, Any}()

register_event(name::AbstractString, t::Any) = event_register[name] = t

find_event(name::AbstractString) = haskey(event_register, name) ? event_register[name] : nothing


