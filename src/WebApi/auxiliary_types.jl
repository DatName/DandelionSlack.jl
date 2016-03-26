export UserId, ChannelId, TeamId
export SlackName


@newimmutable UserId <: AbstractString
@stringinterface UserId

@newimmutable ChannelId <: AbstractString
@stringinterface ChannelId

@newimmutable TeamId <: AbstractString
@stringinterface TeamId

@newimmutable GroupId <: AbstractString
@stringinterface GroupId

@newimmutable ImId <: AbstractString
@stringinterface ImId

@newimmutable BotId <: AbstractString
@stringinterface BotId

@newimmutable SlackName <: AbstractString
@stringinterface SlackName

@newimmutable MpimName <: AbstractString
@stringinterface MpimName

@newimmutable BotName <: AbstractString
@stringinterface BotName

@newimmutable Timestamp <: Integer
