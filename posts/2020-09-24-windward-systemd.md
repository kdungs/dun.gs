---
title: How to set up a Windward server on GCP and some insights about systemd
author: Kevin
date: 2020-09-24
---

> [Windward](https://store.steampowered.com/app/326410/) is an action-filled
> multiplayer sandbox game that puts you in control of a ship sailing the high
> seas of a large procedurally-generated world.

Thanks to the recent Steam Pirate Sale and my friend Alex, I started playing
Windward. For technical reasons, we had to set up a dedicated server which
turned out to be fairly simple and has the added benefit of asynchronous play
that since then lured in more players (shout out to Patrick!).

This article touches on three important aspects:

- [How to set up a virtual machine on the Google Cloud Platform (GCP) Compute
  Engine to host our server](#set-up-a-gcp-compute-engine-vm)
- [How to set up a dedicated Windward server under
  Linux](#configure-linux-to-run-the-windward-server)
- [How to make systemd user services, mono, and Windward play together
  nicely](#epilogue-why-tmux)

The third section explains the details behind some choices in the second
section and is not required reading if you just want to set up your own server.
If you want to understand why the service makes use of `tmux` in such a weird
way, read until the end.


# Set up a GCP Compute Engine VM

For this, you can follow the excellent, official tutorial at
<https://cloud.google.com/community/tutorials/setup-arma-server-compute-engine>
almost step by step until right before the section "Set up the Arma server".

The key differences are:

- An `e2-micro (2 vCPU, 1GB memory)` instance will be powerful enough.
- In the firewall, port 5127 should be open for incoming TCP traffic.

Also make sure to chose a zone (both for the instance and the external IP) that
anticipates where your players will come from. E.g. on my server, all players
are from Germany, so I chose `europe-west3 (Frankfurt)`.


# Configure Linux to run the Windward server

Once you can connect to the machine via SSH (see
<https://cloud.google.com/compute/docs/instances/connecting-to-instance#gcetools>
if you're unsure how), as a first order of business, create a dedicated user.
This is to avoid running the server binary with the (sudo) privileges of your
account. Also, in order to allow the server to start automatically when the
machine starts, [enable lingering](https://www.freedesktop.org/software/systemd/man/loginctl.html#enable-linger%20USER%E2%80%A6)
for the newly created user.

```bash
sudo adduser wward
sudo usermod -L wward
sudo loginctl enable-linger wward
```

Install `mono` which is needed to run the (.NET) binary and other tools we'll
need long the way. Updating the server also shouldn't hurt…

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y mono-complete tmux unzip
```

Switch to the user we just created via `sudo su wward` and set the following
environment variables so you're able to use `systemctl` as `wward`.

```bash
export XDG_RUNTIME_DIR="/run/user/$UID"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
```

Download the server binary from the official source. (Alternatively, you can
also find it in your Steam folder under `Steam/steamapps/common/Windward/`.)

```bash
curl -O http://www.tasharen.com/windward/WWServer.zip
unzip WWServer.zip
rm WWServer.zip
```

In order to be able to actually start a campaign, you'll have to create it
manually, by running the game on your local machine and starting a new
campaign.  Once the corresponding `.dat` and `.dat.config` files show up under
`%AppData\Bla\` (**TBD**), copy them into `~/Windward/Worlds/` on your server.
The rest of the tutorial will assume that your campaign is called "MyCampaign".
You might have to replace that name with whatever you chose in the following
steps.

Then, create a script called `~/start-server.sh` with the following contents

```bash
#!/bin/bash

/usr/bin/mono ~/WWServer.exe \
        -name "Foo Server" \
        -world "MyCampaign" \
        -tcp 5127
```

Make it executable via `chmod +x ~/start-server.sh`. If you want your server to
appear on the public list of available game servers, you can also specify
the `-public` option.

Then, create `~/.config/systemd/user/windward.service` with the following
contents

```
[Unit]
Description=Windward Dedicated Server

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/tmux new-session -d -s Windward %h/start-server.sh
ExecStop=/usr/bin/tmux send-keys -t Windward q Enter Enter

[Install]
WantedBy=default.target
```

Enable and start the service via

```bash
systemctl --user enable windward.service
systemctl --user start windward.service
```

You should be all good to go. All the best and may you always have enough water
under your keel.


# Epilogue: Why tmux?

The avid reader might be confused about the use of `tmux` here. Why not just
start the server directly in the service and be done with it? That is exactly
what I did when I first migrated the server from a tmux session to a "proper"
systemd user service. On the same day, we noticed larger latencies in game but
I didn't attribute them to the change. Only when I saw the CPU usage on the GCP
dashboard the next day, I noticed that it had jumped from below 20% to over 80%
the moment I moved the server to a systemd service.

Very quickly, I found [this thread on
Stackexchange](https://unix.stackexchange.com/questions/191621/systemd-service-using-100-of-my-cpu-when-it-doesnt-if-i-start-it-without-syste)
where someone describes a very similar problem. Incidentally, they are also
using `mono`. As it turns out, `mono` is not the problem, though.

As one commenter notes,

> Systemd runs process without stdin (=/dev/null). All syscalls to read() are
> finished immediately (with normal stdin, read() is blocked until new data
> arrive).

Unfortunately, the Windward server waits for input on stdin. Running it in the
aforementioned fashion will result in the server spamming the output and
continously reading from /dev/null/. If you try to run the server as a systemd user service directly, you'll see many lines similar to this one in `journalctl`:

```
Sep 24 13:55:59 windward-server start-server.sh[631]: [2020/09/24 13:55:59] \
Press 'q' followed by ENTER when you want to quit.
```

Another commenter suggests using the
[`StandardInput=tty`](https://freedesktop.org/software/systemd/man/systemd.exec.html#StandardInput=)
option. Unfortunately, this does not work here, as our user can't interact with
the TTY. I'm not sure if this is because of the VM or because of insufficient
privileges, but I couldn't get it to work so I started looking for
alternatives. I also tried files and named pipes but none would reliably bring
the load down.

The author of the aforementioned thread discovered that they could get the load
down by running their executable inside `screen`. After knowing about the
problem with reading from stdin, this is no longer surprising, as the process
inside screen will have their own stdin and stdout. Using `tmux` instead of
screen, and some insight from [another discussion on
Serverfault](https://serverfault.com/questions/178457/can-i-send-some-text-to-the-stdin-of-an-active-process-running-in-a-screen-sessi/547144#547144),
I even found a nice way to terminate the server in the intended way: tmux
allows us to send keystrokes to the running program, so we can configure the
service to use that to bring down the server:

```
ExecStop=/usr/bin/tmux send-keys -t Windward q Enter Enter
```

Very nice indeed.
