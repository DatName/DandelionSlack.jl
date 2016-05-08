export UsersList, UsersListResponse

@slackmethod(UsersList, "users.list",
    begin
        presence::Nullable{Int}
    end,

    begin
        members::Vector{User}
    end)