defmodule InstaData.Instagram.Post do
    
    alias InstaData.Instagram.Query
    alias InstaData.Instagram.Query.PageInfo

    
    #-------------------------------
    # PUBLIC API
    #-------------------------------

    defstruct [
        post_id: nil,
        post_code: nil,
        post_type: :image,
        timestamp: nil,
        caption: nil,
        hashtags: [],        
        total_likes: 0,
        video_url: nil,
        picture: nil,
        total_comments: 0,
        total_views: 0,
        user_id: nil,
        username: nil,                
        user: %InstaData.Instagram.User{},
        comments: [],
        likes: []
        
    ]

    def get(post_id) when is_binary(post_id) do
        get_post(post_id)
    end
    

    def get(post_id, callback_function) 
    when is_binary(post_id) and is_function(callback_function, 1)do
        cast_message({:get_post, post_id, callback_function})
    end

    def get_user_posts(username, options, callback) 
        when is_binary(username) and is_function(callback, 1) and is_list(options) do 
        
            per_page = Keyword.get(options, :per_page, 10)
            max_count = Keyword.get(options, :max_count, -1)

            args = %{username: username, per_page: per_page, max_count: max_count, callback: callback}

            {:ok, server} = GenServer.start_link(__MODULE__,args)
            cast_message(server, {:get_user_posts})

    end
    
    def get_user_posts(user_id, options, callback) 
    when is_integer(user_id) and is_function(callback, 1) and is_list(options) do 
        
                
    end 

    #--------------------------------------------------
    # OTP IMPLEMENTATIONS
    #--------------------------------------------------

    def init(%{}=args)do  
        IO.inspect(args)      
        {:ok, args}       
    end

    def init(_)do        
        {:ok, []}       
    end

    defp cast_message(server, message)do        
        GenServer.cast(server, message)
    end

    defp cast_message(message)do
        {:ok, server} = GenServer.start_link(__MODULE__, [])
        GenServer.cast(server, message)
    end    

    def start_link(username, max, per_page \\ 10)do
        GenServer.start_link(__MODULE__, [%{username: username, max: max, per_page: per_page}])
    end

    
    def terminate(reason, state)do
        IO.puts("Terminating process #{inspect self()} with state: #{inspect state}")
    end

   
    def handle_info({:init, %{username: username, max: max, per_page: per_page}=args}, state)do
        user = InstaData.Instagram.User.get(username)
        url = "/graphql/query/" #?query_id=17888483320059182&id=#{user_id}&first=#{max}"        
        q = Query.query(url, [query_id: 17888483320059182, id: user.id, first: per_page])
        new_state = %{query: q, user: user, username: username, max: max, per_page: per_page}
        {:noreply, new_state}
    end

    def handle_info({:next, :get_user_posts}, %{total_posts: total_posts, total_found: total_found, next: after_page, user_id: user_id, username: username, per_page: per_page, max_count: max_count, callback: callback}=state)
    do

        

        url = "/graphql/query/" 
        q = %Query{url: url, params: [after: after_page, query_id: 17888483320059182, id: user_id, first: per_page]}
        %{total: total, posts: posts, next: next} = user_posts_with_query(q)
        total_fetched = Enum.count(posts)

        case callback.({username, %{total: total, posts: posts}}) do
            :stop -> 
                {:noreply, state}
            :continue ->
                case max_count < 1 do
                    true->
                        

                        if (total_found + total_fetched) >= total_posts do
                            # first page result not even enough
                            #end of result
                            callback.(:done)
                            #stop_procees(self)
                            {:stop, :normal, state}
                        else
                            new_state = %{user_id: user_id, 
                                username: username, 
                                per_page: per_page, 
                                max_count: max_count,
                                next: next,
                                callback: callback,
                                total_posts: total,
                                total_found: total_found + total_fetched
                            }
                            Process.send_after(self(),{:next, :get_user_posts},1000)
                            {:noreply, new_state}
                        end
                    false ->

                        left = max_count - total_fetched
                        case left > 0 do
                            true ->
                                new_state = %{
                                    user_id: user_id, 
                                    username: username, 
                                    per_page: per_page, 
                                    max_count: left,
                                    next: next,
                                    callback: callback,
                                    total_posts: total,
                                    total_found: total_found + total_fetched
                                }

                                Process.send_after(self(),{:next, :get_user_posts},1000)
                                {:noreply, new_state}
                            _ ->
                                callback.(:done)
                                #stop_procees(self)
                                {:stop, :normal, state}
                        end
                                                                                          
                end
                                            
        end

    end
    

    def handle_cast({:get_user_posts}, %{username: username, per_page: per_page, max_count: max_count, callback: callback}=state)
     do

        
        case InstaData.Instagram.User.get(username)do
            %InstaData.Instagram.User{id: user_id}->                
                url = "/graphql/query/" 
                q = %Query{url: url, params: [query_id: 17888483320059182, id: user_id, first: per_page]}
                %{total: total, posts: posts, next: next} = user_posts_with_query(q)
                total_fetched = Enum.count(posts)

                case callback.({username, %{total: total, posts: posts}}) do
                    :stop -> 
                        callback.({username, :done})
                        #stop_procees(self)
                        {:stop, :normal, state}
                    :continue ->
                        case max_count < 1 do
                            true->
                                if total_fetched < per_page do
                                    # first page result not even enough
                                    #end of result
                                    callback.({username, :done})
                                    {:noreply, state}
                                else
                                    new_state = %{user_id: user_id, 
                                        username: username, 
                                        per_page: per_page, 
                                        max_count: max_count,
                                        next: next,
                                        callback: callback,
                                        total_posts: total,
                                        total_found: total_fetched
                                    }
                                    Process.send_after(self(),{:next, :get_user_posts},1000)
                                    {:noreply, new_state}
                                end
                            false ->

                                left = max_count - total_fetched
                                case left > 0 do
                                    true ->
                                        new_state = %{
                                            user_id: user_id, 
                                            username: username, 
                                            per_page: per_page, 
                                            max_count: left,
                                            next: next,
                                            callback: callback,
                                            total_posts: total,
                                            total_found: total_fetched
                                        }
        
                                        Process.send_after(self(),{:next, :get_user_posts},1000)
                                        {:noreply, new_state}
                                    _ ->
                                        callback.({username, :done})
                                        #stop_procees(self)
                                        {:stop, :normal, state}
                                end
                                                                                                  
                        end
                                                    
                end
            other ->
                IO.inspect(other)
                callback.({username, :user_not_found})
                #stop_procees(self)
                {:stop, :normal, state}
        end                

        
    end

    def handle_cast({:get_post, post_id, callback}, state)
    when is_binary(post_id) and is_function(callback, 1) do
        data = get_post(post_id)
        callback.({post_id, data})
        {:noreply, state}
    end

    def handle_cast(:next, %{user: user, max: max, per_page: per_page}=state)do
        {:noreply, state}
    end

    
    def handle_cast({:user_posts, username, pid}, state)do
        data = user_posts(username, -1)
        send(pid, {{:user_posts, username}, data})
        {:noreply, state}
    end

    # def handle_cast({:user_posts, username, pid}, state)do
    #     data = InstaData.Instagram.Post.user_posts(username)
    #     send(pid, {{:user_posts, username}, data})
    #     {:noreply, state}
    # end

    def handle_cast({:user_posts, _query, username, pid}, state)do
        data = user_posts(username, -1)
        send(pid, {{:user_posts, username}, data})
        {:noreply, state}
    end


    
    #---------------------
    # INTERNALS
    # ---------------------

    defp next(pid)do
        GenServer.cast(pid, :next)
    end

    

    defp get_post(post_id)do
        case InstaData.HTTP.Instagram.get("/p/"<>post_id<>"?__a=1", [], [follow_redirect: true]) do
            {:ok, %{body: body}}->
                process_post(body[:graphql] |>  Map.get("shortcode_media"))
            _ ->
                :error    
        end

    end

    defp process_post(%{
        "edge_media_to_caption"=>%{"edges"=>captions},
        "edge_media_to_comment"=>%{"count"=>total_comments},
        "id"=>post_id,
        "display_url"=>picture,
        "is_video"=>is_video,
        "shortcode"=>code,
        "taken_at_timestamp"=>timestamp,
        #"edge_media_preview_like"=>%{"count"=>total_likes},
        "owner"=>%{"id"=>user_id}=owner

        } = p)do
        
            user = %InstaData.Instagram.User{
                id: String.to_integer(user_id),
                username: Map.get(owner, "username"),
                name: Map.get(owner, "name"),
                picture: Map.get(owner, "profile_pic_url")
            }



            caption = case List.first(captions)do
                nil -> nil
                %{"node"=>%{"text"=>text}} -> text
            end

            total_likes = case Map.get(p,"edge_media_preview_like", Map.get(p, "edge_liked_by"))do
                nil -> 0
                %{"count"=> count}-> count
            end

            %__MODULE__{
                post_id: String.to_integer(post_id),
                user_id: String.to_integer(user_id),
                username: Map.get(owner, "username"),
                caption: caption,
                timestamp: timestamp,
                post_code: code,
                video_url: Map.get(p, "video_url"),
                picture: picture,
                total_views: Map.get(p, "video_view_count"),
                total_likes: total_likes,
                total_comments: total_comments,
                user: user,
                post_type: case is_video do
                    true -> :video
                    _ -> :image
                end
            }
    end

    defp user_posts_with_query(q)do
        {:ok, data} = Query.run(q)       
        
        media =
        data[:data] 
        |> Map.get("user")
        |> Map.get("edge_owner_to_timeline_media")
        
        page_info = media["page_info"]
        q = Query.add_page_info(q, page_info)        
        

        total = media["count"]
        items = media["edges"]
        
        posts = Enum.reduce(items, [], fn post, acc ->
            List.insert_at(acc, -1, process_post(post["node"]))
        end)

        %{total: total, posts: posts, next: case q.page_info.has_next_page do
             true -> q.page_info.end_cursor
             _ -> nil
        end
    }
    end

    defp user_posts(username, max)do
        user_posts(username, -1)
    end

    defp user_posts(user_id, max, after_page) when is_integer(user_id) and is_integer(max) do
        url = "/graphql/query/" #?query_id=17888483320059182&id=#{user_id}&first=#{max}"
        
        q = %Query{url: url, params: [after: after_page, query_id: 17888483320059182, id: user_id, first: max]}
        user_posts_with_query(q)
    end

    defp user_posts(user_id, max) when is_integer(user_id) and max <= 50 and max >= 0 do
        url = "/graphql/query/" #?query_id=17888483320059182&id=#{user_id}&first=#{max}"
        q = %Query{url: url, params: [query_id: 17888483320059182, id: user_id, first: max]}
        user_posts_with_query(q)
    end
    
    

    defp user_posts(username, max)do
       case InstaData.Instagram.User.get(username) do
           %InstaData.Instagram.User{id: user_id}=user->
                %{total: total, posts: posts, next: q} = user_posts(user_id, max)
                %{user: user, total: total, posts: posts, next: q}
            _ ->
                :error
       end

    end

    defp user_posts(username, max, after_page)do
        case InstaData.Instagram.User.get(username) do
            %InstaData.Instagram.User{id: user_id}=user->
                 %{posts: posts, total: total, next: q} = get_user_posts(user_id, max, after_page)
                 %{user: user, total: total, posts: posts, next: q}
             _ ->
                 :error
        end
 
     end


     #Hastag search
    def hashtag(tag_name)do
        search_hashtag(tag_name, 1)
        |> get_hashtag_posts()
    end

    def top_hashtag(tag_name)do
        search_hashtag(tag_name, 20)
        |> get_top_hashtag_posts()
    end

    defp get_top_hashtag_posts(data)do
        posts = 
        data[:data]["hashtag"]["edge_hashtag_to_top_posts"]["edges"]
        |> Enum.map(fn p -> 
            process_post(p["node"])
        end)
        #page_info = data[:data]["hashtag"]["edge_hashtag_to_media"]["page_info"]
        %{total: Enum.count(posts),  
        posts: posts, next: nil}
    end

    defp get_hashtag_posts(data)do
        posts = 
        data[:data]["hashtag"]["edge_hashtag_to_media"]["edges"]
        |> Enum.map(fn p -> 
            process_post(p["node"])
        end)
        page_info = data[:data]["hashtag"]["edge_hashtag_to_media"]["page_info"]
        %{total: data[:data]["hashtag"]["edge_hashtag_to_media"]["count"],  posts: posts, next: case page_info["has_next_page"] do
            true -> page_info["end_cursor"]
            _ -> nil
        end}
    end

    defp search_hashtag(tag_name, per_page)do
        search_hashtag(tag_name, per_page, nil)
    end 
    defp search_hashtag(tag_name, per_page, after_page)do
        #graphql/query/?query_id=17882293912014529&tag_name={0}&first=100&after={1}
        q = Query.query("/graphql/query/", [query_id: "17882293912014529", tag_name: tag_name, first: per_page, after: after_page])
        {:ok, data} = Query.run(q)
        data
    end

    defp search_users(username, per_page, after_page)do
        
    end


    end