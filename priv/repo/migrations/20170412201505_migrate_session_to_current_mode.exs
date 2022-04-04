defmodule Ask.Repo.Migrations.MigrateSessionToCurrentMode do
  import Ecto.Query
  import Ecto
  use Ecto.Migration
  alias Ask.Repo

  defmodule Channel do
    use Ask.Web, :model

    schema "channels" do
      field :type, :string
    end
  end

  defmodule Respondent do
    use Ask.Web, :model

    schema "respondents" do
      field :session, Ask.Ecto.Type.JSON
      field :state, :string, default: "pending"
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:session])
    end
  end

  defprotocol SessionMode do
    def dump(session_mode)
  end

  defmodule SMSMode do
    defstruct [:channel, :retries]

    def new(channel, retries) do
      %SMSMode{channel: channel, retries: retries}
    end

    def load(mode_dump) do
      %SMSMode{
        channel: Channel |> Repo.get(mode_dump["channel_id"]),
        retries: mode_dump["retries"]
      }
    end

    defimpl SessionMode, for: SMSMode do
      def dump(%SMSMode{channel: channel, retries: retries}) do
        %{
          mode: "sms",
          channel_id: channel.id,
          retries: retries
        }
      end
    end
  end

  defmodule IVRMode do
    defstruct [:channel, :retries]

    def new(channel, retries) do
      %IVRMode{channel: channel, retries: retries}
    end

    def load(nil), do: nil

    def load(mode_dump) do
      %IVRMode{
        channel: Channel |> Repo.get(mode_dump["channel_id"]),
        retries: mode_dump["retries"]
      }
    end

    defimpl SessionMode, for: IVRMode do
      def dump(%IVRMode{channel: channel, retries: retries}) do
        %{
          mode: "ivr",
          channel_id: channel.id,
          retries: retries
        }
      end
    end
  end

  defmodule MobileWebMode do
    defstruct [:channel, :retries]

    def new(channel, retries) do
      %MobileWebMode{channel: channel, retries: retries}
    end

    def load(nil), do: nil

    def load(mode_dump) do
      %MobileWebMode{
        channel: Channel |> Repo.get(mode_dump["channel_id"]),
        retries: mode_dump["retries"]
      }
    end

    defimpl SessionMode, for: MobileWebMode do
      def dump(%MobileWebMode{channel: channel, retries: retries}) do
        %{
          mode: "mobileweb",
          channel_id: channel.id,
          retries: retries
        }
      end
    end
  end

  defmodule SessionModeProvider do
    defp mode_provider("sms"), do: SMSMode
    defp mode_provider("ivr"), do: IVRMode
    defp mode_provider("mobileweb"), do: MobileWebMode

    def new(nil, _channel, _retries), do: nil

    def new(mode, channel, retries) when not is_nil(channel) and is_list(retries) do
      mode_provider(mode).new(channel, retries)
    end

    def load(nil), do: nil

    def load(mode_dump) do
      mode_provider(mode_dump["mode"]).load(mode_dump)
    end

    def dump(nil), do: nil

    def dump(mode) do
      mode |> SessionMode.dump()
    end
  end

  def up do
    change_respondents(&upgrade/1)
  end

  def down do
    change_respondents(&downgrade/1)
  end

  defp change_respondents(change_function) do
    Repo.all(from r in Respondent, where: r.state == :active)
    |> Enum.each(fn respondent ->
      respondent
      |> Respondent.changeset(%{
        session: change_function.(respondent.session)
      })
      |> Repo.update!()
    end)
  end

  defp upgrade(state) do
    state
    |> load_old
    |> upgrade_session
    |> dump_new
  end

  defp downgrade(state) do
    state
    |> load_new
    |> downgrade_session
    |> dump_old
  end

  defp upgrade_session(%{channel: channel, retries: retries, fallback: nil} = session) do
    %{
      current_mode: SessionModeProvider.new(channel.type, channel, retries),
      fallback_mode: nil,
      flow: session.flow,
      respondent: session.respondent,
      token: session.token,
      fallback_delay: session.fallback_delay,
      channel_state: session.channel_state,
      count_partial_results: session.count_partial_results
    }
  end

  defp upgrade_session(
         %{channel: channel, retries: retries, fallback: {fallback_channel, fallback_retries}} =
           session
       ) do
    %{
      current_mode: SessionModeProvider.new(channel.type, channel, retries),
      fallback_mode:
        SessionModeProvider.new(fallback_channel.type, fallback_channel, fallback_retries),
      flow: session.flow,
      respondent: session.respondent,
      token: session.token,
      fallback_delay: session.fallback_delay,
      channel_state: session.channel_state,
      count_partial_results: session.count_partial_results
    }
  end

  defp upgrade_session(session), do: session

  defp downgrade_session(%{current_mode: current_mode, fallback_mode: nil} = session) do
    %{
      channel: current_mode.channel,
      flow: session.flow,
      respondent: session.respondent,
      retries: current_mode.retries,
      fallback: nil,
      token: session.token,
      fallback_delay: session.fallback_delay,
      channel_state: session.channel_state,
      count_partial_results: session.count_partial_results
    }
  end

  defp downgrade_session(%{current_mode: current_mode, fallback_mode: fallback_mode} = session) do
    %{
      channel: current_mode.channel,
      flow: session.flow,
      respondent: session.respondent,
      retries: current_mode.retries,
      fallback: channel_tuple(fallback_mode.channel, fallback_mode.retries),
      token: session.token,
      fallback_delay: session.fallback_delay,
      channel_state: session.channel_state,
      count_partial_results: session.count_partial_results
    }
  end

  defp downgrade_session(session), do: session

  defp dump_new(session) do
    %{
      current_mode: (session.current_mode || nil) |> SessionModeProvider.dump(),
      fallback_mode: session.fallback_mode |> SessionModeProvider.dump(),
      flow: session.flow,
      respondent_id: session.respondent,
      token: session.token,
      fallback_delay: session.fallback_delay,
      channel_state: session.channel_state,
      count_partial_results: session.count_partial_results
    }
  end

  defp load_new(state) do
    %{
      current_mode: SessionModeProvider.load(state["current_mode"]),
      fallback_mode: SessionModeProvider.load(state["fallback_mode"]),
      flow: state["flow"],
      respondent: state["respondent_id"],
      token: state["token"],
      fallback_delay: state["fallback_delay"],
      channel_state: state["channel_state"],
      count_partial_results: state["count_partial_results"]
    }
  end

  defp dump_old(session) do
    %{
      channel_id: session.channel.id,
      flow: session.flow,
      respondent_id: session.respondent,
      retries: session.retries,
      fallback_channel_id: fallback_channel_id(session.fallback),
      fallback_retries: fallback_retries(session.fallback),
      token: session.token,
      fallback_delay: session.fallback_delay,
      channel_state: session.channel_state,
      count_partial_results: session.count_partial_results
    }
  end

  defp load_old(state) do
    %{
      channel: Repo.get(Channel, state["channel_id"]),
      flow: state["flow"],
      respondent: state["respondent_id"],
      retries: state["retries"],
      fallback:
        channel_tuple(fallback_channel(state["fallback_channel_id"]), state["fallback_retries"]),
      token: state["token"],
      fallback_delay: state["fallback_delay"],
      channel_state: state["channel_state"],
      count_partial_results: state["count_partial_results"]
    }
  end

  defp channel_tuple(nil, _), do: nil
  defp channel_tuple(channel, retries), do: {channel, retries}

  defp fallback_channel(nil), do: nil

  defp fallback_channel(id) do
    Repo.get(Channel, id)
  end

  defp fallback_channel_id(nil), do: nil
  defp fallback_channel_id({channel, _}), do: channel.id

  defp fallback_retries(nil), do: nil
  defp fallback_retries({_, retries}), do: retries
end
