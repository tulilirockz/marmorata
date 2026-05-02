# Marmorata

A few Podman Quadlet containers I've been using to host a few apps on my home server. Should be used in conjunction with [taxifolia](https://github.com/tulilirockz/taxifolia) or similar system. This is primarily designed for my deployments so a few configuration files might be specific to it.

All state related to this should be stored under `$HOME/srv/(volume-name-here)` or temporary podman volumes. Quadlets get installed following the [`podman-quadlet`](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) documentation.

> [!NOTE]
> There are no stability guarantees, this goes by whatever my own deployments need, so if you need stable paths, fork this repository!

## How to deploy anything here

Make sure you have [`just`](https://github.com/casey/just), then clone this repository, `cd` to your desired deployment, and run `just` on it.

```bash
git clone https://github.com/tulilirockz/marmorata.git
cd marmorata
cd your-service # i.e.: searxng
just # This will install the quadlet for you, most of them will launch on boot.
just start # Manually start up the service
just stop # Manually stops the service (makes it so it doesn't run on reboot!)
just clean # Removes state related to the service and stops it (does not remove anything under `$HOME/srv`)
```

### Optional for sharing with other computers

You can expose the services if you are utilizing `firewalld`:

```bash
cd your-service # i.e.: searxng
just firewall # IF you want to expose the service to other computers
firewall-cmd --add-service=(your-service) # i.e.: searxng
```
