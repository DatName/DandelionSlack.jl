export UserId, ChannelId, TeamId
export SlackName


@newimmutable UserId <: AbstractString
@stringinterface UserId

@newimmutable ChannelId <: AbstractString
@stringinterface ChannelId

@newimmutable TeamId <: AbstractString
@stringinterface TeamId

@newimmutable SlackName <: AbstractString
@stringinterface SlackName

3