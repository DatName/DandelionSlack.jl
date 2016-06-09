export TeamJoinEvent

@slackevent(TeamJoinEvent, "team_join", begin
        user::User
    end)
