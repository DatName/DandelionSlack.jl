import Base.==

export
    Self,
    Token,
    SlackChannel

immutable Self
    id::UserId
    name::SlackName
    created::UInt64
    manual_presence::UTF8String
end

function ==(a::Self, b::Self)
    a.id == b.id && a.name == b.name && a.created == b.created &&
        a.manual_presence == b.manual_presence
end

immutable Team
    id::TeamId
    name::SlackName
    email_domain::UTF8String
    domain::UTF8String
end

immutable Profile
    first_name::Nullable{SlackName}
    last_name::Nullable{SlackName}
    real_name::SlackName
    email::Nullable{UTF8String}
    skype::Nullable{UTF8String}
end

immutable User
    id::UserId
    name::SlackName
    deleted::Bool
    color::Nullable{UTF8String}
    profile::Profile
    is_admin::Nullable{Bool}
    is_owner::Nullable{Bool}
    is_primary_owner::Nullable{Bool}
    is_restricted::Nullable{Bool}
    is_ultra_restricted::Nullable{Bool}
    has_2fa::Nullable{Bool}
    two_factor_type::Nullable{UTF8String}
    has_files::Nullable{Bool}
end

immutable Topic
    value::UTF8String
    creator::UTF8String
    last_set::UInt64
end

immutable Purpose
    value::UTF8String
    creator::UTF8String
    last_set::UInt64
end

immutable Icons
    image_36::UTF8String
    image_48::UTF8String
    image_72::UTF8String
end

immutable Message
    type_::UTF8String
    user::UserId
    text::UTF8String
    ts::UTF8String
end

immutable Mpim
    id::GroupId
    name::MpimName
    is_mpim::Bool
    is_group::Bool
    created::Timestamp
    creator::UserId
    members::Vector{UserId}
    last_read::UTF8String
    latest::Message
    unread_count::UInt64
    unread_count_display::UInt64
end

immutable Im
    id::ImId
    is_im::Bool
    user::UserId
    created::Timestamp
    is_user_deleted::Nullable{Bool}
end

immutable SlackChannel
    id::ChannelId
    name::SlackName
    is_channel::Bool
    created::UInt64
    creator::UTF8String
    is_archived::Bool
    is_general::Bool
    members::Nullable{Vector{UTF8String}}
    topic::Nullable{Topic}
    purpose::Nullable{Purpose}
    is_member::Bool
    last_read::Nullable{UTF8String}
    unread_count::Nullable{UInt64}
    unread_count_display::Nullable{UInt64}
end

immutable Group
    id::GroupId
    name::SlackName
    is_group::UTF8String
    created::Timestamp
    creator::UserId
    is_archived::Bool
    is_mpim::Bool
    members::Vector{UserId}
    topic::Topic
    purpose::Purpose

    last_read::Nullable{UTF8String}
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