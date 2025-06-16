defmodule NervesGlamCam.Button do
  use GenServer

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(args) do
    gpio_name = Keyword.fetch!(args, :gpio)
    send_to = Keyword.fetch!(args, :send_to)
    name = Keyword.fetch!(args, :name)

    debounce_time = Keyword.get(args, :debounce_time, 200)
    long_press_time = Keyword.get(args, :long_press_time, 2_000)

    {:ok, gpio} = Circuits.GPIO.open(gpio_name, :input, pull_mode: :pullup)

    Circuits.GPIO.set_interrupts(gpio, :both)

    state =
      %{
        gpio: gpio,
        name: name,
        send_to: send_to,
        debounce_time: debounce_time,
        long_press_time: long_press_time,
        last_press: nil,
        timer_ref: nil
      }

    {:ok, state}
  end

  @impl true
  def handle_info({:circuits_gpio, _gpio, _time, 0}, state) do
    # button was pressed, debounce here!
    now = NaiveDateTime.utc_now()

    Logger.info("BUTTON DOWN")

    if is_nil(state.last_press) or
         NaiveDateTime.diff(now, state.last_press, :millisecond) > state.debounce_time do
      send(state.send_to, {:button_down, state.name})

      if not is_nil(state.timer_ref), do: :timer.cancel(state.timer_ref)

      {:noreply, put_in(state.last_press, now)}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:circuits_gpio, _gpio, _time, 1}, state) do
    Logger.info("BUTTON UP")

    if not is_nil(state.last_press) do
      now = NaiveDateTime.utc_now()
      press_duration = NaiveDateTime.diff(now, state.last_press, :millisecond)

      if press_duration > state.debounce_time do
        send(state.send_to, {:button_up, state.name, press_duration})
        {:noreply, put_in(state.last_press, nil)}
      else
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end
end
