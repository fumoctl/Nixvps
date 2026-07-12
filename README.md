# Nixvps

My NixOS config for my VPS

## SSH with port exposing

```
waypipe -c lz4  ssh -i ~/.ssh/key -L 9090:localhost:9090 [user]@[IP_ADDRESS]
```

## Install/Deploy

```
nix run github:nix-community/nixos-anywhere -- \
  --flake .#vps \
  --ssh-option "IdentityFile=~/.ssh/key" \
  [user]@[IP_ADDRESS]
```

## Update

```
sudo nix flake update
```

```
NIX_SSHOPTS="-i ~/.ssh/key" nixos-rebuild switch \
  --flake .#vps \
  --target-host root@[IP_ADDRESS]
```

## sshuttle
```
sshuttle -r [user]@[IP_ADDRESS] 0/0 --ssh-cmd 'ssh -i ~/.ssh/key' --python python3
```
