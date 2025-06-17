# Nerves Glam Cam

A Nerves-powered conference badge, first displayed at ElixirConf EU 2025.
Featuring an e-ink display and a tiny onboard camera, this project is designed
to showcase a fun use-case of Nerves.

![Nerves Glam Cam](/docs/IMG_3061.jpg)

> [!NOTE]
> Do you want to learn how to write an e-ink driver and get some e-ink hardware
> to take home? I'm running a workshop at several upcoming conferences, based on
> this project. Check it out -
> [ElixirConf US](https://elixirconf.com/trainings/dip-your-toes-into-hardware-with-nerves/)
> and
> [CodeBEAM Europe](https://codebeameurope.com/trainings/dip-your-toes-into-hardware-with-nerves/)
>
> Feel free to contact me if you're interested or have any questions!

## Functions

| Button | Press Type | Action                                      |
| ------ | ---------- | ------------------------------------------- |
| Red    | Any        | Capture an image and show it on the display |
| Black  | Short      | Cycle through the loaded slides             |
| Black  | Long (5s)  | Power off (low power mode)                  |

## Hardware

Nerves Glam Cam is made of several components:

- Raspberry Pi Zero 2W
- [Soleil](https://protolux.io/projects/soleil) board for power management,
  battery charging and sleep mode
- 4.2", 400x300 e-ink display (I used
  [this one from Good Display](https://www.good-display.com/product/386.html))
- 24-pin e-ink SPI display adapter (I used
  [this one from Good Display](https://www.good-display.com/product/516.html))
- Tiny MIPI-CSI2 camera (I used
  [this OV5647-based one from AliExpress](https://www.aliexpress.com/item/32782501654.html))
- Some 3D printed parts and some superglue. STEP files are available in the
  `mechanical` directory

![Nerves Glam Cam - under the hood](/docs/IMG_3040.jpg)

## Key Implementation Details

It's a surprisingly small amount of code required to build this app and make it
run. There's two areas which are not super trivial though:

### E-Ink Display Driver

The e-ink display contains a SSD1683 driver chip, and is controlled using an SPI
interface. The `NervesGlamCam.EInk` module handles initialization, configuring
parameters like dimensions and operating mode, writing pixel data to the display
buffer, and enabling power-saving sleep mode.

The
[device datasheet](https://v4.cecdn.yun300.cn/100001_1909185148/GDEY042T81.pdf)
contains example code which served as the starting point for the software driver
in this repo.

### Image Processing

Images go through a standard processing pipeline to prepare them for display.
The source of the images can be static images (such as the pre-rendered slides,
which are just JPEG files) or dynamic images captured by the camera. First, an
image is converted to black and white, then resized to fit the screen
dimensions, and finally dithered using the Floyd-Steinberg algorithm. To handle
dithering, I cross compiled the Rust-based
[dither tool](https://crates.io/crates/dither) by Efron Licht. Finally, the
processed image is formatted to match the display driver requirements and
written to the buffer for rendering.

## Getting Started

If you've gone through the trouble of acquiring all the hardware, and want to
run this on your own device:

- `export MIX_TARGET=soleil_rpi0_2` or prefix every command with
  `MIX_TARGET=soleil_rpi0_2`. If you don't have the Soleil board for power
  management, you can also just use a target of `rpi0_2`.
- Set your WiFi credentials as environment variables, `NERVES_WIFI_SSID` and
  `NERVES_WIFI_PASSPHRASE`
- Install dependencies with `mix deps.get`
- Create firmware with `mix firmware`
- Burn to an SD card with `mix burn`

## Future Updates

The first version as shown at ElixirConf EU 2025 was bare-bones (I threw it
together in a weekend!). For the next conference, I'd like to make a few
updates:

- [ ] Support 4-bit grayscale for nicer images (especially text and fonts)
- [ ] Better button debounce
- [ ] More static slides
- [ ] Make it more social and interactive!

Stay tuned... v2 coming at Goatmire in September 2025 :eyes:

## Gallery

![Nerves Glam Cam](/docs/IMG_3076.jpg) ![Nerves Glam Cam](/docs/IMG_3113.jpg)
![Nerves Glam Cam](/docs/IMG_3123.jpg) ![Nerves Glam Cam](/docs/IMG_3126.jpg)
![Nerves Glam Cam](/docs/IMG_3128.jpg)
