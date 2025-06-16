defmodule NervesGlamCam.Camera do
  def take_photo(folder, opts \\ []) do
    {w, h} = Keyword.get(opts, :resolution, {640, 480})
    timeout = Keyword.get(opts, :timeout, 1000)
    file_name = Keyword.get(opts, :file_name, "capture.jpg")

    file_path = Path.join(folder, file_name)

    MuonTrap.cmd("libcamera-jpeg", [
      "-n",
      "--immediate",
      "--width",
      to_string(w),
      "--height",
      to_string(h),
      "-t",
      to_string(timeout),
      "-o",
      file_path
    ])
    |> case do
      {_, 0} -> {:ok, file_path}
      {_, error_code} -> {:error, error_code}
    end
  end
end
