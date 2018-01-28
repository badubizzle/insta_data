# InstaData

Elixir Library for Accessing Instagram Public Data without API Key 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `insta_data` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:insta_data, "~> 0.1.0"}
  ]
end
```

##Usage
alias InstaData.Instagram

### Get user Instagram profile with ```username```
sync:
```elixir
Instagram.Users.get("instagram")
```
async:

```elixir
Instagram.Users.get("instagram", fn %User{} -> 

end)
```

### Get Single Instagram post
sync:
```elixir
Instagram.Posts.get("BJYkFQPgwGD")
```
async:
```elixir
Instagram.Posts.get("BJYkFQPgwGD", fn %Post{} ->

end)
```

### Get Instagram User's Posts
async:
```elixir
Instagram.Posts.get_user_posts("instagram",[per_page: 10, limit: 100], fn (%{posts: posts, total: total}) ->
  :continue | :stop
end)
```


### Search for posts with Hashtag

```elixir
Instagram.Search.hashtag("chalewote", [], fn posts ->

end)
```

```elixir
Instagram.Search.search_users("badu", fn users -> 

end)
```


