import Base.==

export
    Self,
    Token,
    SlackChannel,
    Team

struct Self
    id::UserId
    name::SlackName
    created::UInt64
    manual_presence::String
end

function ==(a::Self, b::Self)
    a.id == b.id && a.name == b.name && a.created == b.created &&
        a.manual_presence == b.manual_presence
end

struct Team
    id::TeamId
    name::SlackName
    email_domain::String
    domain::String
end

struct Profile
    first_name::Nullable{SlackName}
    last_name::Nullable{SlackName}
    real_name::SlackName
    email::Nullable{String}
    skype::Nullable{String}
end

struct User
    id::UserId
    name::SlackName
    deleted::Bool
    color::Nullable{String}
    profile::Profile
    is_admin::Nullable{Bool}
    is_owner::Nullable{Bool}
    is_primary_owner::Nullable{Bool}
    is_restricted::Nullable{Bool}
    is_ultra_restricted::Nullable{Bool}
    has_2fa::Nullable{Bool}
    two_factor_type::Nullable{String}
    has_files::Nullable{Bool}
end

struct Topic
    value::String
    creator::String
    last_set::UInt64
end

struct Purpose
    value::String
    creator::String
    last_set::UInt64
end

struct Icons
    image_36::String
    image_48::String
    image_72::String
end

struct Message
    type_::String
    user::UserId
    text::String
    ts::String
end

struct Mpim
    id::GroupId
    name::MpimName
    is_mpim::Bool
    is_group::Bool
    created::Timestamp
    creator::UserId
    members::Vector{UserId}
    last_read::String
    latest::Message
    unread_count::UInt64
    unread_count_display::UInt64
end

struct Im
    id::ImId
    is_im::Bool
    user::UserId
    created::Timestamp
    is_user_deleted::Nullable{Bool}
end

struct SlackChannel
    id::ChannelId
    name::SlackName
    is_channel::Bool
    created::UInt64
    creator::String
    is_archived::Bool
    is_general::Bool
    members::Nullable{Vector{String}}
    topic::Nullable{Topic}
    purpose::Nullable{Purpose}
    is_member::Bool
    last_read::Nullable{String}
    unread_count::Nullable{UInt64}
    unread_count_display::Nullable{UInt64}
end

struct Group
    id::GroupId
    name::SlackName
    is_group::String
    created::Timestamp
    creator::UserId
    is_archived::Bool
    is_mpim::Bool
    members::Vector{UserId}
    topic::Topic
    purpose::Purpose

    last_read::Nullable{String}
    latest::Nullable{Message}
    unread_count::Nullable{UInt64}
    unread_count_display::Nullable{UInt64}
end

struct Bot
    id::BotId
    deleted::Bool
    name::BotName
    icons::Nullable{Icons}
end
