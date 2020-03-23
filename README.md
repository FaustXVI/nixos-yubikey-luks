# LUKS-Encrypted Filesystem with Yubikey PBA
In this guide, we describe how to set up an encrypted filesystem with Yubikey pre-boot authentication (PBA) on NixOS. While the focus is on NixOS, the same techniques should be able to be used on any Linux system where Linux Unified Key Setup (LUKS) is available.

This guide is inspired by and based on [Yubikey based Full Disk Encryption (FDE) on NixOS](https://nixos.wiki/wiki/Yubikey_based_Full_Disk_Encryption_(FDE)_on_NixOS).

Other methods exist for other Linux distributions:

 * ArchLinux: [Yubikey Full Disk Encryption](https://github.com/agherzan/yubikey-full-disk-encryption)
 * Debian: [Yubikey for Luks](https://github.com/cornelinux/yubikey-luks)

## Design
We have the option of using either one (1FA) or two (2FA) factors for authentication. Using 1FA, the Yubikey must be inserted to open the LUKS device, but no extra passphrase is required. With 2FA, once the Yubikey is inserted, we'll be asked to enter a passphrase in order to open the LUKS device.

We'll program the Yubikey in Challenge-Response (HMAC-SHA1) mode in an alternate slot. Then we'll calculare the `salt` and `iterations` and store them on an unencrypted partition. These values will be used to calculate the challenge for the Yubikey. The response, along with a user-entered passphrase in 2FA, will be used to calculate the LUKS key.

At boot time, NixOSs Yubikey PBA will read the `salt` and `iterations`, which is again used to calculate the challenge. The Yubikey's response will be used to calculate the LUKS key. If we're using 2FA, we'll enter a passphrase which will be combined with the challenge-response key. If the key is successfully unlocked, NixOS will recalculate the `salt` and `iterations` values, and the expected Yubikey response. It will use the response to update the LUKS key so the passphrase is different at each time the machine is booted.

## Requirements
Before beginning the process, it's assumed that you have

 * An unencrypted partition (Here we use ESP, but any partition is fine)
 * A Yubikey with a free configuration slot
 * A running NixOS system
 
### Setup
For convenience, I've created a Nix expression that includes all dependencies. Enter the nix-shell:

    nix-shell https://github.com/FaustXVI/nixos-yubikey-luks/archive/master.tar.gz
    
Use the `encrypt-script`
