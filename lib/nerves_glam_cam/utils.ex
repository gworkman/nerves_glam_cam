defmodule NervesGlamCam.Utils do
  alias Evision, as: CV

  def resize(image, opts \\ []) do
    w = Keyword.get(opts, :width, 400)
    h = Keyword.get(opts, :height, 300)

    CV.resize(image, {w, h}, interpolation: CV.Constant.cv_INTER_AREA())
    |> IO.inspect(label: "RESIZED")
  end

  def prepare_for_eink(image) do
    {_, binary_image} = CV.threshold(image, 127, 1, CV.Constant.cv_THRESH_BINARY())

    binary_image
    |> Evision.Mat.to_binary()
    |> :erlang.binary_to_list()
    |> Enum.chunk_every(8)
    |> Enum.map(fn [b1, b2, b3, b4, b5, b6, b7, b8] ->
      <<b1::1, b2::1, b3::1, b4::1, b5::1, b6::1, b7::1, b8::1>>
    end)
    |> Enum.join("")
  end

  def take_and_prepare_image() do
    {:ok, dir} = Temp.mkdir()

    {:ok, img_path} = NervesGlamCam.Camera.take_photo(dir)

    img =
      img_path
      |> CV.imread(flags: CV.Constant.cv_IMREAD_GRAYSCALE())
      |> resize()

    bw_path = Path.join(dir, "bw_image.jpg")
    CV.imwrite(bw_path, img)
    {:ok, dither_path} = dither(bw_path)

    CV.imread(dither_path, flags: CV.Constant.cv_IMREAD_GRAYSCALE())
    |> prepare_for_eink()
  end

  def dither(image_path, opts \\ []) do
    depth = Keyword.get(opts, :depth, 1)
    file_name = Keyword.get(opts, :file_name, "dithered.jpg")
    folder = Path.dirname(image_path)
    file_path = Path.join(folder, file_name)

    dither_path()
    |> MuonTrap.cmd(["--depth", to_string(depth), image_path, file_path])
    |> case do
      {_, 0} -> {:ok, file_path}
      {_, error_code} -> {:error, error_code}
    end
  end

  defp dither_path do
    Application.app_dir(:nerves_glam_cam, "priv/dither")
  end
end
