export UsersList, UsersListResponse

@slackmethod(UsersList, "users.list",
    begin
        presence::Nullable{Int}
    end,

    begin
        users::Vector{User}
    end)