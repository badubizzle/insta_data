defmodule InstaData.Instagram.Query.PageInfo do
    defstruct [
        has_next_page: nil,
        end_cursor: nil
    ]
end

defmodule InstaData.Instagram.Query do
    
    defstruct [
        url: nil,
        params: [],
        page_info: nil
    ]

    def query(url, params) do
        %__MODULE__{url: url, params: params}        
    end

    def add_page_info(%__MODULE__{}=q, %InstaData.Instagram.Query.PageInfo{}=page_info)do
        %__MODULE__{q | page_info: page_info}
    end

    def add_page_info(%__MODULE__{}=q, %{"has_next_page"=> has_next_page,
    "end_cursor"=>cursor})do
        %__MODULE__{q | page_info: %InstaData.Instagram.Query.PageInfo{has_next_page: has_next_page, end_cursor: cursor}}
    end


    def run(%__MODULE__{url: url, params: params, page_info: nil}=q)do
        url = url <> "?" <> URI.encode_query(Map.new(filter_params(params)))
        IO.inspect(url)
        {:ok, %{body: data}} = InstaData.HTTP.Instagram.get(url, [], [follow_redirect: true])                
        {:ok, data}
    end

    def run(%__MODULE__{url: url, params: params, 
    page_info: %InstaData.Instagram.Query.PageInfo{has_next_page: true, end_cursor: after_page}}=q)do
        url = url <> "?" <> URI.encode_query(Map.new(filter_params(params) ++ [after: after_page]))
        {:ok, %{body: data}} = InstaData.HTTP.Instagram.get(url, [], [follow_redirect: true])                
        {:ok, data}
    end

    defp filter_params(params)do
        params |> Enum.filter(fn{k, v} -> v != nil end)
    end

end
