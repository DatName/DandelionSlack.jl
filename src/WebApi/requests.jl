using Requests

immutable Status
    ok::Bool
    error::Nullable{AbstractString}
    warnings::Nullable{AbstractString}
end

