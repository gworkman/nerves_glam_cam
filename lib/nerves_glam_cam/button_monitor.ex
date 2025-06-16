defmodule NervesGlamCam.ButtonMonitor do
  use GenServer

  alias NervesGlamCam.EInk
  alias NervesGlamCam.Button
  alias Evision, as: CV

  @red_button "GPIO23"
  @black_button "GPIO15"

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  def init(_args) do
    {:ok, _} = Button.start_link(gpio: @red_button, send_to: self(), name: :red)
    {:ok, _} = Button.start_link(gpio: @black_button, send_to: self(), name: :black)

    eink = EInk.new("spidev0.0", "GPIO21", "GPIO20", "GPIO16")

    image =
      slides()
      |> Enum.at(0)
      |> CV.imread(flags: CV.Constant.cv_IMREAD_GRAYSCALE())
      |> CV.flip(-1)
      |> NervesGlamCam.Utils.prepare_for_eink()

    EInk.draw_image(eink, image)

    {:ok, %{eink: eink, slide: 0}}
  end

  @impl true
  def handle_info({:button_down, :red}, state) do
    image = NervesGlamCam.Utils.take_and_prepare_image()
    EInk.draw_image(state.eink, image)

    {:noreply, state}
  end

  def handle_info({:button_down, :black}, state), do: {:noreply, state}

  def handle_info({:button_up, :red, _duration}, state), do: {:noreply, state}

  def handle_info({:button_up, :black, duration}, state) when duration > 5_000 do
    Soleil.power_off()
    {:noreply, state}
  end

  def handle_info({:button_up, :black, duration}, state) when duration <= 5_000 do
    IO.inspect("BLACK BUTTON PRESSED")
    new_slide = rem(state.slide + 1, length(slides()))

    image =
      slides()
      |> Enum.at(new_slide)
      |> CV.imread(flags: CV.Constant.cv_IMREAD_GRAYSCALE())
      |> CV.flip(-1)
      |> NervesGlamCam.Utils.prepare_for_eink()

    EInk.draw_image(state.eink, image)

    {:noreply, put_in(state.slide, new_slide)}
  end

  defp slides do
    slides_dir = Application.app_dir(:nerves_glam_cam, "priv/slides")

    slides_dir
    |> File.ls!()
    |> Enum.map(&Path.join(slides_dir, &1))
    |> Enum.sort()
  end
end
