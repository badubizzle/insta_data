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

## Usage

```elixir
alias InstaData.Instagram
```

### Get user Instagram profile with ```username```
sync:
```elixir
Instagram.User.get("instagram")
```
async:

```elixir
Instagram.User.get("instagram", 
fn ({_username, %Instagram.User{}=user}) -> 
  IO.puts("Found user #{inspect(user)}")
  {_, :error} -> 
  IO.puts("Error occurred")

end)
```

### Get Single Instagram post With Post ID
For a post with url like this https://www.instagram.com/p/BJYkFQPgwGD
sync:
```elixir
Instagram.Post.get("BJYkFQPgwGD")
```
async:
```elixir
Instagram.Post.get("BJYkFQPgwGD", 
fn ({_post_id, %Instagram.Post{}=post}) ->
  IO.puts("Found post: #{inspect(post)}")
  ({_post_id, :error}) ->
  IO.puts("Error occurred")
end)
```

### Get Instagram User's Posts
async:
```elixir
Instagram.Post.get_user_posts("instagram",[per_page: 10, limit: 100], 
fn ({_username, %{posts: posts, total: total}}) ->
    IO.puts("Found posts: #{inspect(posts)}")
    :continue # return :continue to continue or :stop to stop next batch
   ({_username, :done}) -> 
    IO.puts("Done")
    ({_username, :user_not_fount})->
      IO.put("User not found")

end)
```


### Search for posts with Hashtag

```elixir
Instagram.Search.hashtag("chalewote", [], 
fn posts ->

end)
```

```elixir
Instagram.Search.search_users("badu", 
fn users -> 

end)
```


