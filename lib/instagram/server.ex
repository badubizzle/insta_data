defmodule InstaData.HTTP.Instagram do
    use HTTPoison.Base
        
    def process_url(url) do
        "https://instagram.com" <> url
    end

    def process_response_body(body) do
        body
        |> Poison.decode!
        #|> Map.take(@expected_fields)
        |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
    end
    
end

defmodule InstaData.Instagram.UserQuery do
    use GenServer

    def init(_)do 
        {:ok, []}       
    end

    def start_link()do
        GenServer.start_link(__MODULE__, [])
    end

    def get_user(username, pid)do
        GenServer.cast(__MODULE__, {:user, username, pid})
    end

    def handle_cast({:user, username, pid}, state)do
        user = InstaData.Instagram.User.get(username)
        send(pid, {:user, user})
        {:noreply, state}
    end

    

end