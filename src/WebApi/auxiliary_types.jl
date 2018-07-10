export UserId, ChannelId, TeamId, EventTimestamp
export SlackName


@newimmutable UserId <: String
@stringinterface UserId

@newimmutable ChannelId <: String
@stringinterface ChannelId

@newimmutable TeamId <: String
@stringinterface TeamId

@newimmutable GroupId <: String
@stringinterface GroupId

@newimmutable ImId <: String
@stringinterface ImId

@newimmutable BotId <: String
@stringinterface BotId

@newimmutable SlackName <: String
@stringinterface SlackName

@newimmutable MpimName <: String
@stringinterface MpimName

@newimmutable BotName <: String
@stringinterface BotName

@newimmutable Timestamp <: UInt64

@newimmutable Token <: String
@stringinterface Token

@newimmutable EventTimestamp <: String
@stringinterface EventTimestamp
