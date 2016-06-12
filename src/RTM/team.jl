export TeamJoinEvent,
       TeamMigrationStarted

@slackevent(TeamJoinEvent, "team_join", begin
        user::User
    end)

@slackevent(TeamMigrationStarted, "team_migration_started", begin end)