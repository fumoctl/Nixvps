# Nixvps

My NixOS config for my VPS

```
nix run github:nix-community/nixos-anywhere -- \
  --flake .#vps \
  --ssh-option "IdentityFile=~/.ssh/key" \
  [user]@[IP_ADDRESS]
```
