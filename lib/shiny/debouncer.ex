defmodule Shiny.Debouncer do
  use GenServer

  def start_link(f, delay) do
    GenServer.start_link(__MODULE__, %{delay: delay, function: f, scheduled: false})
  end

  def init(arg) do
    {:ok, arg}
  end

  def handle_call({:run, args}, _, state = %{scheduled: true}) do
    {:reply, nil, state}
  end

  def handle_call({:run, args}, _, state) do
    Process.send_after(self(), {:exec, args}, state.delay)
    {:reply, nil, %{state | scheduled: true}}
  end

  def handle_info({:exec, args}, state) do
    apply(state.function, args)
    {:noreply, %{state | scheduled: false}}
  end

  def call(pid, args) do
    GenServer.call(pid, {:run, args})
  end
end
