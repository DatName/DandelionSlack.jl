export Event

abstract OutgoingEvent
abstract Event

macro slackevent(event_type::Symbol, event_name::AbstractString, event_block::Expr)
    quote
        immutable $event_type <: Event
            $(event_block.args...)
        end

        $(esc(:register_event))($event_name, $event_type)
    end
end

macro slackoutevent(event_type::Symbol, event_name::AbstractString, event_block::Expr)
    quote
        immutable $event_type <: OutgoingEvent
            $(event_block.args...)
        end

        $(esc(:outgoing_event_name))(::Type{$(esc(event_type))}) = $event_name
    end
end

function serialize(e::OutgoingEvent)
    s = Dict{UTF8String, Any}(
        utf8("type") => outgoing_event_name(typeof(e)))
    for f in fieldnames(e)
        s[utf8(string(f))] = getfield(e, f)
    end
    s
end
