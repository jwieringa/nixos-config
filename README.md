# nixos-config
My NixOS configurations

Credit: [https://github.com/mitchellh/nixos-config](https://github.com/mitchellh/nixos-config/tree/01fcaea3bdcd47540da39446d80e85d042a70cc1)

## Instructions

Boot virtual machine with minimal nixos iso. Set root password.

```
sudo su
passwd
```

Fetch IP address.

```
ip addr show
```

Set nixos IP address and bootstrap.

```
export NIXADDR=<VM_IP>
make vm/bootstrap
```
