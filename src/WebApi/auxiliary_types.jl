export UserId, ChannelId, TeamId, EventTimestamp
export SlackName


@newimmutable UserId <: UTF8String
@stringinterface UserId

@newimmutable ChannelId <: UTF8String
@stringinterface ChannelId

@newimmutable TeamId <: UTF8String
@stringinterface TeamId

@newimmutable GroupId <: UTF8String
@stringinterface GroupId

@newimmutable ImId <: UTF8String
@stringinterface ImId

@newimmutable BotId <: UTF8String
@stringinterface BotId

@newimmutable SlackName <: UTF8String
@stringinterface SlackName

@newimmutable MpimName <: UTF8String
@stringinterface MpimName

@newimmutable BotName <: UTF8String
@stringinterface BotName

@newimmutable Timestamp <: UInt64

@newimmutable Token <: UTF8String
@stringinterface Token

@newimmutable EventTimestamp <: UTF8String
@stringinterface EventTimestamp