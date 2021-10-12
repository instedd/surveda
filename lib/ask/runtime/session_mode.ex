defprotocol Ask.Runtime.SessionMode do
  def dump(session_mode)
  def visitor(session_mode)
  def mode(session_mode)
end

defmodule Ask.Runtime.SessionModeProvider do
  alias Ask.Runtime.{SessionMode, SMSMode, IVRMode, MobileWebMode, SMSSimulatorMode, IVRSimulatorMode, MobileWebSimulatorMode}
  alias Ask.{Repo, Channel}

  defp mode_provider("sms"), do: SMSMode
  defp mode_provider("ivr"), do: IVRMode
  defp mode_provider("mobileweb"), do: MobileWebMode

  def new(nil, _channel, _retries), do: nil

  def new("sms", %Ask.Runtime.SimulatorChannel{} = channel, retries) do
    SMSSimulatorMode.new(channel, retries)
  end

  def new("ivr", %Ask.Runtime.SimulatorChannel{} = channel, retries) do
    IVRSimulatorMode.new(channel, retries)
  end

  def new("mobileweb", %Ask.Runtime.SimulatorChannel{} = channel, retries) do
    MobileWebSimulatorMode.new(channel, retries)
  end

  def new(mode, channel, retries) when not is_nil(channel) and is_list(retries) do
    mode_provider(mode).new(channel, retries)
  end

  def load(nil), do: nil
  def load(mode_dump) do
    mode_provider(mode_dump["mode"]).load(mode_dump)
  end

  def dump(nil), do: nil
  def dump(mode) do
    mode |> SessionMode.dump
  end

  def mode(nil), do: nil
  def mode(mode) do
    mode |> SessionMode.mode
  end

  def visitor(nil), do: nil
  def visitor(mode) do
    mode |> SessionMode.visitor
  end
end

defmodule Ask.Runtime.SMSSimulatorMode do
  alias __MODULE__
  alias Ask.Runtime.Flow.TextVisitor

  defstruct [:channel, :retries]

  def new(channel, retries), do: %SMSSimulatorMode{channel: channel, retries: retries}
  def load(_mode_dump), do: %SMSSimulatorMode{}

  defimpl Ask.Runtime.SessionMode, for: Ask.Runtime.SMSSimulatorMode do
    def dump(%SMSSimulatorMode{}) do
      %{
        mode: "sms",
      }
    end

    def visitor(_) do
      TextVisitor.new("sms")
    end

    def mode(_) do
      "sms"
    end
  end
end

# FIXME: duplicate of Ask.Runtime.SMSSimulatorMode
defmodule Ask.Runtime.IVRSimulatorMode do
  alias __MODULE__
  alias Ask.Runtime.Flow.TextVisitor

  defstruct [:channel, :retries]

  def new(channel, retries), do: %IVRSimulatorMode{channel: channel, retries: retries}
  def load(_mode_dump), do: %IVRSimulatorMode{}

  defimpl Ask.Runtime.SessionMode, for: Ask.Runtime.IVRSimulatorMode do
    def dump(%IVRSimulatorMode{}) do
      %{
        mode: "ivr",
      }
    end

    def visitor(_) do
      TextVisitor.new("ivr")
    end

    def mode(_) do
      "ivr"
    end
  end
end

defmodule Ask.Runtime.SMSMode do
  alias __MODULE__
  alias Ask.Runtime.Flow.TextVisitor
  alias Ask.{Repo, Channel}

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

  defimpl Ask.Runtime.SessionMode, for: Ask.Runtime.SMSMode do
    def dump(%SMSMode{channel: channel, retries: retries}) do
      %{
        mode: "sms",
        channel_id: channel.id,
        retries: retries
      }
    end

    def visitor(_) do
      TextVisitor.new("sms")
    end

    def mode(_) do
      "sms"
    end
  end
end


defmodule Ask.Runtime.IVRMode do
  alias __MODULE__
  alias Ask.Runtime.Flow.TextVisitor
  alias Ask.{Repo, Channel}

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

  defimpl Ask.Runtime.SessionMode, for: Ask.Runtime.IVRMode do
    def dump(%IVRMode{channel: channel, retries: retries}) do
      %{
        mode: "ivr",
        channel_id: channel.id,
        retries: retries
      }
    end

    def visitor(_) do
      TextVisitor.new("ivr")
    end

    def mode(_) do
      "ivr"
    end
  end
end

defmodule Ask.Runtime.MobileWebMode do
  alias Ask.Runtime.Flow.WebVisitor
  alias Ask.{Repo, Channel}
  alias __MODULE__

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

  defimpl Ask.Runtime.SessionMode, for: Ask.Runtime.MobileWebMode do
    def dump(%MobileWebMode{channel: channel, retries: retries}) do
      %{
        mode: "mobileweb",
        channel_id: channel.id,
        retries: retries
      }
    end

    def visitor(_) do
      WebVisitor.new("mobileweb")
    end

    def mode(_) do
      "mobileweb"
    end
  end
end

defmodule Ask.Runtime.MobileWebSimulatorMode do
  alias __MODULE__
  alias Ask.Runtime.Flow.WebVisitor

  defstruct [:channel, :retries]

  def new(channel, retries), do: %MobileWebSimulatorMode{channel: channel, retries: retries}
  def load(_mode_dump), do: %MobileWebSimulatorMode{}

  defimpl Ask.Runtime.SessionMode, for: Ask.Runtime.MobileWebSimulatorMode do
    def dump(%MobileWebSimulatorMode{}) do
      %{
        mode: "mobileweb",
      }
    end

    def visitor(_) do
      WebVisitor.new("mobileweb")
    end

    def mode(_) do
      "mobileweb"
    end
  end
end
