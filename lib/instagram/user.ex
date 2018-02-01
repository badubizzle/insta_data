defmodule InstaData.Instagram.User do
    

    #PUBLIC API

    defstruct [
        id: nil,
        username: nil,
        name: nil,
        picture: nil,
        bio: nil,        
        private: false,
        verified: false,
        followers: 0,
        following: 0,
        total_posts: 0,
        total_saved_posts: 0,
        url: nil
    ]

    @doc """
    Get Instagram User Profile with given `username`
    
    Return {username, %Instagram.User{}} | {username, :error}

    ##Example
    iex> user = Instagram.User.get("instagram")    
    """
    def get(username) when is_binary(username)do
        user = get_user(username)
        user
    end


    
    @doc """
    Get Instagram User Profile with given `username` and `callback_function/1`
    callback function that will be called with
    `{username, %Instagram.User{}} | {username, :error}`    
    
    ##Example
    iex> Instagram.User.get("instagram", 
    fn({username, %Instagram.User{}=user}) -> 
        IO.puts("User found: " <> IO.inspect((user))
       ({username, :error})->
        IO.puts("Error occurred")         
    end)
    """
    def get(username, callback_function) when is_binary(username) and is_function(callback_function,1) do
        {:ok, server} = start_link()
        GenServer.cast(server, {:user, username, callback_function})
    end


    # OTP IMPLEMENTATIONS

    def init(_)do 
        {:ok, []}       
    end

    def start_link()do
        GenServer.start_link(__MODULE__, [])
    end
        
    def handle_cast({:user, username, callback}, state) when is_function(callback) do
        user = get_user(username)
        callback.({username, user})
        {:stop, :normal, state}
    end

    def handle_cast({:user, username, pid}, state)do
        user = get_user(username)
        send(pid, {{:user, username}, user})
        {:noreply, state}
    end


    @base_url "https://instagram.com"
    
    defp get_user(username, pid)do
        {:ok, server} = start_link()
        GenServer.cast(server, {:user, username, pid})
    end


    defp get_user(username)do
        case InstaData.HTTP.Instagram.get("/"<>username<>"?__a=1", [], [follow_redirect: true]) do
            {:ok, %HTTPoison.Response{body: data}} ->
                process_user(data[:user])
            error ->
                IO.inspect(error)
                :error
        end
    end

    defp process_user(%{"external_url"=>url, "biography"=>bio, "full_name"=>name, 
    "followed_by"=>%{"count"=> followers}, 
    "follows"=> %{"count"=>following}, 
    "is_private"=>is_private, "id"=> user_id, 
    "is_verified"=>is_verified, 
    "media"=>%{"count"=> total_posts},
    "username"=>username, 
    "profile_pic_url_hd"=>picture,
    "saved_media"=>%{"count"=>total_saved_posts}})do        

        %__MODULE__{id: String.to_integer(user_id), 
            username: username,
            name: name,
            picture: picture,
            bio: bio,
            private: is_private,
            verified: is_verified,
            followers: followers,
            following: following,
            total_posts: total_posts,
            total_saved_posts: total_saved_posts,
            url: url
        }
    end
end