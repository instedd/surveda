defmodule Ask.FloipEndpoint do
  use Ask.Web, :model

  @primary_key false
  schema "floip_endpoints" do
    field :name, :string
    field :uri, :string, primary_key: true
    field :last_pushed_response_id, :integer
    field :retries, :integer

    field :state, :string, default: "enabled" # disabled | enabled | terminated
    field :auth_token, :string, default: ""

    belongs_to :survey, Ask.Survey, primary_key: true

    timestamps()
  end
end