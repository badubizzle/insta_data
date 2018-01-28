defmodule InstaData.Instagram.Search do
    use GenServer

    alias InstaData.Instagram.Query


    def hashtag(tag_name)do
        search_hashtag(tag_name, 20)
    end
    

    defp search_hashtag(tag_name, per_page)do
        search_hashtag(tag_name, per_page, nil)
    end 

    defp search_hashtag(tag_name, per_page, after_page)do
        #graphql/query/?query_id=17882293912014529&tag_name={0}&first=100&after={1}
        q = %Query{url: "/graphql/query/", params: [query_id: "17882293912014529", tag_name: tag_name, first: per_page, after: after_page]}
        {:ok, data} = Query.run(q) 

        data
    end

    

end