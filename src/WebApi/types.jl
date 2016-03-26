import Base.==

export Self

immutable Self
    id::UserId
    name::SlackName
    created::UInt64
    manual_presence::AbstractString
end

function ==(a::Self, b::Self)
    a.id == b.id && a.name == b.name && a.created == b.created &&
        a.manual_presence == b.manual_presence
end

immutable Team
    id::TeamId
    name::SlackName
    email_domain::AbstractString
    domain::AbstractString
end

immutable Profile
    first_name::SlackName
    last_name::SlackName
    real_name::SlackName
    email::AbstractString
    skype::AbstractString
end

immutable User
    id::UserId
    name::SlackName
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

immutable Icons
    image_36::AbstractString
    image_48::AbstractString
    image_72::AbstractString
end

immutable Message
    type_::AbstractString
    user::UserId
    text::AbstractString
    ts::AbstractString
end

immutable Mpim
    id::GroupId
    name::MpimName
    is_mpim::Bool
    is_group::Bool
    created::Timestamp
    creator::UserId
    members::Array{UserId}
    last_read::AbstractString
    latest::Message
    unread_count::UInt64
    unread_count_display::UInt64
end

immutable Im
    id::ImId
    is_im::Bool
    user::UserId
    created::Timestamp
    is_user_deleted::Bool
end

immutable Channel
    id::ChannelId
    name::SlackName
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

immutable Group
    id::GroupId
    name::SlackName
    is_group::AbstractString
    created::Timestamp
    creator::UserId
    is_archived::Bool
    is_mpim::Bool
    members::Array{UserId}
    topic::Topic
    purpose::Purpose

    last_read::Nullable{AbstractString}
    latest::Nullable{Message}
    unread_count::Nullable{UInt64}
    unread_count_display::Nullable{UInt64}
end

immutable Bot
    id::BotId
    deleted::Bool
    name::BotName
    icons::Nullable{Icons}
end