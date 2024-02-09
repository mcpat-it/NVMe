<p align="center">
  <img class="comment" height="200px" src="https://github.com/mcpat-it/NVMe/raw/main/images/rpi.svg" alt="rpi"/>
</p>

# NVMe for Raspberry Pi (5)
[![Donate to this project using PayPal](https://shields.io/badge/Paypal-Donate-blue?logo=paypal&style=flat)](https://www.paypal.com/donate/?business=2667RS4MQ9M5Y&no_recurring=1&item_name=Please+support+me+if+you+like+my+work.+Thank+you%21&currency_code=EUR)
[![Donate to this project using Buy Me A Coffee](https://shields.io/badge/Buy%20me%20a%20coffee-Donate-yellow?logo=buymeacoffee&style=flat)](https://buymeacoff.ee/mcpat)
[![LICENSE](https://shields.io/badge/license-GPL-lightgrey)](https://raw.githubusercontent.com/mcpat-it/NVMe/main/LICENSE)
[![Platform](https://shields.io/badge/platform-linux--64%20(aarch64)-lightgrey)](https://github.com/mcpat-it/NVMe)
[![GitHub issues open](https://img.shields.io/github/issues/mcpat-it/NVMe)](https://github.com/mcpat-it/NVMe/issues)
[![Downloads total](https://img.shields.io/github/downloads/mcpat-it/NVMe/total)](https://github.com/mcpat-it/NVMe/releases)
[![Latest release](https://img.shields.io/github/v/release/mcpat-it/NVMe)](https://github.com/mcpat-it/NVMe/releases)

[![forks](https://img.shields.io:/github/forks/mcpat-it/NVMe?style=social)](https://github.com/mcpat-it/NVMe)
[![stars](https://img.shields.io:/github/stars/mcpat-it/NVMe?style=social)](https://github.com/mcpat-it/NVMe)
[![watchers](https://img.shields.io:/github/watchers/mcpat-it/NVMe?style=social)](https://github.com/mcpat-it/NVMe)
[![followers](https://img.shields.io:/github/followers/mcpat-it?style=social)](https://github.com/mcpat-it)

## Project Notes

**Author:** Patrick Wallner

The repository idea is based on giving as much help as possible to have an easy start.

Please see below for instructions on how to install the associated utils.

## Table of Contents

  * [Why GPTconverter](#why-gptconverter)
  * [Install](#install)
  * [How to use GPT converter](#how-to-use-GPT-converter)
  * [Support my work](#support-my-work)
  * [FAQ](#faq)

## Why GPTconverter
Most of the images are preparted with MBR and therefore are limited to 2TB. This simple script converts to GPT and therefore there is no 2TB limit anymore (ok, there is a 18EB limit).

## Install
> ⚠️ **Cause of lacking of time, this is only tested on my Rpi5 with latest Bookworm!** 

One simple step:

1a. Connect to your device via SSH and type the following command to download and execute GPT converter.

    sudo -i
    bash <(curl -s https://nvme.mcpat.com/gptconverter.sh)
or

1b. Alternative you can download and execute the script

    cd
    wget https://raw.githubusercontent.com/mcpat-it/NVMe/main/gptconverter.sh
    chmod +x gptconverter.sh
    sudo ./gptconverter.sh

## How to use GPT converter
1. Boot your pi with a SD card and already installed NVMe, and install an image with `imager` on the rpi desktop, you can also make the settings (e.g. username, password, wifi, ...)
2. Make sure with `raspi-config` the boot order is `B1: SD Card Boot Boot from SD card if available, otherwise boot from NVMe`.
3. Power off the system and remove SD card and power on again
4. After the pi has booted and everything runs well (e.g. wifi connection), power off again and insert SD card again
5. Power on and wait system is ready
6. Run the command as descripted in section "Install" in the commandline
7. Power off the system and remove the SD, reboot to NVMe again and be happy

## Support my work
I'm a working single dad and this is only my hobby which I did in my rare free time. So I really appreciate if you make a small donation to let me buy some sweets for my son!

[!["Buy Me A Coffee"](https://github.com/mcpat-it/NVMe/raw/main/images/coffee.png)](https://buymeacoff.ee/mcpat)
[![Support via PayPal](https://github.com/mcpat-it/NVMe/raw/main/images/paypal.svg)](https://www.paypal.com/donate/?business=2667RS4MQ9M5Y&no_recurring=1&item_name=Please+support+me+if+you+like+my+work.+Thank+you%21&currency_code=EUR)
<!-- [![Donate](https://www.paypalobjects.com/en_US/AT/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate/?business=2667RS4MQ9M5Y&no_recurring=1&item_name=Please+support+me+if+you+like+my+work.+Thank+you%21&currency_code=EUR) -->
[![Donate](https://github.com/mcpat-it/NVMe/raw/main/images/QR-Code.png)](https://www.paypal.com/donate/?business=2667RS4MQ9M5Y&no_recurring=1&item_name=Please+support+me+if+you+like+my+work.+Thank+you%21&currency_code=EUR)
## FAQ

<details markdown='1'>

<summary>NVMe does not exist!</summary>
	
 - Ensure your NVMe is correctly installed and can be found at "/dev/nvme0n1"

</details>
<details markdown='1'>

<summary>xxx is mounted!</summary>
	
 - Ensure you booted from SD and you didn't mount any partition manually

</details>
<details markdown='1'>

<summary>System needs firstly a boot from NVMe, remove SD and reboot, then poweroff, insert SD again and run this script again ...</summary>
	
 - Ensure you booted from NVMe once after a fresh installation on NVMe, after this, boot from SD again and run the script again

</details>
<details markdown='1'>

<summary>Unsupported partition table type!</summary>
	
 - Ensure your NVMe is a valid MBR or GPT drive!

</details>
<details markdown='1'>

<summary>GPTconverter doesn't work</summary>
	
 - Open an issue, you know I'm a busy man, but maybe I can help

</details>
