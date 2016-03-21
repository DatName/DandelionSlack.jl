import Base.==

export Self

immutable Self
    id::Id
    name::Name
    created::UInt64
    manual_presence::AbstractString
end

function ==(a::Self, b::Self)
    a.id == b.id && a.name == b.name && a.created == b.created &&
        a.manual_presence == b.manual_presence
end

immutable Team
    id::Id
    name::Name
    email_domain::AbstractString
    domain::AbstractString
end

immutable Profile
    first_name::Name
    last_name::Name
    real_name::Name
    email::AbstractString
    skype::AbstractString
end

immutable User
    id::Id
    name::Name
    deleted::Bool
    color::AbstractString
    profile::Profile
    is_admin::Bool
    is_owner::Bool
    is_primary_owner::Bool
    is_restricted::Bool
    is_ultra_restricted::Bool
    has_2fa::Bool
    two_factor_type::Nullable{AbstractString}
    has_files::Bool
end

immutable Topic
    value::AbstractString
    creator::AbstractString
    last_set::UInt64
end

immutable Purpose
    value::AbstractString
    creator::AbstractString
    last_set::UInt64
end

immutable Channel
    id::Id
    name::Name
    is_channel::Bool
    created::UInt64
    creator::AbstractString
    is_archived::Bool
    is_general::Bool
    members::Array{AbstractString}
    topic::Topic
    purpose::Purpose
    is_member::Bool
    last_read::AbstractString
    unread_count::UInt64
    unread_count_display::UInt64
end