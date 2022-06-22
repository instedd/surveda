defmodule Ask.Runtime.ChannelBrokerSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(_foo, _bar, _baz) do
    # TODO: Check error:
    # docker-compose exec app iex -S mix | Ask.Runtime.ChannelBrokerSupervisor.start_child("foo", "bar", "baz")
    #
    # {:error,
    #   {:function_clause,
    #     [
    #       {Agent, :start_link,
    #       [[],
    #         #Function<0.128151890/0 in Ask.Runtime.ChannelBrokerSupervisor.start_child/3>],
    #       [file: 'lib/agent.ex', line: 263]},
    #       {DynamicSupervisor, :start_child, 3,
    #       [file: 'lib/dynamic_supervisor.ex', line: 690]},
    #       {DynamicSupervisor, :handle_start_child, 2,
    #       [file: 'lib/dynamic_supervisor.ex', line: 676]},
    #       {:gen_server, :try_handle_call, 4, [file: 'gen_server.erl', line: 661]},
    #       {:gen_server, :handle_msg, 6, [file: 'gen_server.erl', line: 690]},
    #       {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 249]}
    #     ]}}

    # spec = {MyWorker, foo: foo, bar: bar, baz: baz}
    spec = {Agent, fn -> %{} end}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end
end
