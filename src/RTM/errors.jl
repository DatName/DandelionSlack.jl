export EventError,
       DeserializationError,
       UnknownEventTypeError,
       MissingTypeError,
       InvalidJSONError

abstract EventError

immutable DeserializationError <: EventError
    key::UTF8String
    text::UTF8String
    event_type::DataType
end

immutable UnknownEventTypeError <: EventError
    text::UTF8String
    event_type::UTF8String
end

immutable MissingTypeError <: EventError
    text::UTF8String
end

immutable InvalidJSONError <: EventError
    text::UTF8String
end