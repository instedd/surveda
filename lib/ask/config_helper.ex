defmodule Ask.ConfigHelper do

  def get_config(module, config_key, sys_config_mapper \\ fn value -> value end) do
    case Application.get_env(:ask, module)[config_key] do
      {:system, env_var} ->
        sys_config_mapper.(System.get_env(env_var))
      {:system, env_var, default} ->
        env_value = System.get_env(env_var)
        if env_value, do: sys_config_mapper.(env_value), else: default
      simple_config -> simple_config
    end
  end
end