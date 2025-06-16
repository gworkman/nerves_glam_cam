defmodule NervesGlamCam.EInk do
  alias Circuits.GPIO
  alias Circuits.SPI

  defstruct [:spi, :busy, :reset, :dc]

  def new(spidev, busy_gpio, reset_gpio, dc_gpio) do
    {:ok, busy} = GPIO.open(busy_gpio, :input)
    {:ok, reset} = GPIO.open(reset_gpio, :output, initial_value: 1, pull_mode: :none)
    {:ok, dc} = GPIO.open(dc_gpio, :output, initial_value: 0, pull_mode: :none)

    {:ok, spi} = SPI.open(spidev)

    %__MODULE__{spi: spi, busy: busy, reset: reset, dc: dc}
  end

  def draw_image(eink, image) when is_binary(image) do
    reset(eink)
    sw_reset(eink)
    initialize(eink)
    load_image(eink, image)
    deep_sleep(eink)
  end

  def reset(eink) do
    GPIO.write(eink.reset, 0)
    Process.sleep(10)
    GPIO.write(eink.reset, 1)

    wait_for_not_busy(eink)
  end

  def sw_reset(eink) do
    write_command(eink, 0x12)
    wait_for_not_busy(eink)
  end

  def deep_sleep(eink) do
    write(eink, 0x10, <<0x03>>)
  end

  def initialize(eink) do
    :ok = write(eink, 0x01, <<0x2B, 0x01, 0x00>>)
    :ok = write(eink, 0x11, <<0x03>>)
    :ok = write(eink, 0x44, <<0x00, 0x31>>)
    :ok = write(eink, 0x45, <<0x00, 0x00, 0x2B, 0x01>>)
    # :ok = write(eink, 0x3C, <<0x01>>)
    :ok = write(eink, 0x21, <<0x40, 0x00>>)
  end

  def load_image(eink, image) when is_binary(image) do
    :ok = write(eink, 0x4E, <<0x00>>)
    :ok = write(eink, 0x4F, <<0x00, 0x00>>)

    wait_for_not_busy(eink)

    for chunk <- chunk(image, 4096) do
      :ok = write(eink, 0x24, chunk)
      wait_for_not_busy(eink)
    end

    wait_for_not_busy(eink)

    write_command(eink, 0x20)
    wait_for_not_busy(eink)
  end

  def write(eink, command, data) do
    write_command(eink, command)
    write_data(eink, data)

    :ok
  end

  defp to_hex(int) do
    hex =
      Integer.to_string(int, 16)
      |> String.pad_leading(2, "0")

    "0x#{hex}"
  end

  def write_command(eink, command) when is_integer(command) and command <= 255 do
    IO.inspect(to_hex(command), label: "Writing Command")

    GPIO.write(eink.dc, 0)
    Circuits.SPI.transfer!(eink.spi, <<command>>)

    :ok
  end

  def write_data(eink, data) when is_integer(data) and data <= 255, do: write_data(eink, <<data>>)

  def write_data(eink, data) when is_binary(data) do
    :erlang.binary_to_list(data)
    |> Enum.map(&to_hex/1)
    |> IO.inspect(label: "Writing Data")

    GPIO.write(eink.dc, 1)
    Circuits.SPI.transfer!(eink.spi, data)

    :ok
  end

  defp wait_for_not_busy(eink) do
    if GPIO.read(eink.busy) > 0, do: wait_for_not_busy(eink), else: :ok
  end

  defp chunk(binary, n, acc \\ [])

  defp chunk(binary, n, acc) when bit_size(binary) <= n do
    Enum.reverse([binary | acc])
  end

  defp chunk(binary, n, acc) do
    <<chunk::size(n), rest::bitstring>> = binary
    chunk(rest, n, [<<chunk::size(n)>> | acc])
  end
end

# image = NervesGlamCam.Utils.take_and_prepare_image()
# NervesGlamCam.EInk.draw_image(eink, image)
