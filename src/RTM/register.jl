event_register = Dict{AbstractString, Any}()

register_event(name::AbstractString, t::Any) = event_register[name] = t

find_event(name::AbstractString) = haskey(event_register, name) ? event_register[name] : nothing

macro slackevent(event_type::Symbol, event_name::AbstractString, event_block::Expr)
    quote
        immutable $event_type <: RTMEvent
            $(event_block.args...)
        end

        $(esc(:register_event))($event_name, $event_type)
    end
end
