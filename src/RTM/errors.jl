export EventError,
       DeserializationError,
       UnknownEventTypeError,
       MissingTypeError,
       InvalidJSONError

abstract type EventError end

struct DeserializationError <: EventError
    key::String
    text::String
    event_type::DataType
end

struct UnknownEventTypeError <: EventError
    text::String
    event_type::String
end

struct MissingTypeError <: EventError
    text::String
end

struct InvalidJSONError <: EventError
    text::String
end
