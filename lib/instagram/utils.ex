defmodule InstaData.Utils do 

    @base_url "https://instagram.com"
    def get_user_url(username)do
        @base_url <> "/" <> username <> "?__a=1"
    end

end