# Phone server scripts for Termux

Installs a SSH server + code-server on [Termux](https://termux.dev/en/)

This lets you use your phone or Termux friendly device as a development box, accessible via [code-server.](https://github.com/coder/code-server)

## One-command setup
```
bash ~/phone-scripts/setup.sh
```

## Scripts
| Script | What it does |
|---|---|
| `start-ssh.sh` | Starts sshd on port 8022, wake-lock, prompts for password if unset, prints connect info. `stop` arg stops it. |
| `start-vscode.sh` | Starts code-server on port 8080, wake-lock, prints URL + password. `stop` arg stops it. |
| `setup.sh` | Fresh-Termux installer (packages + scripts). |

## Connect
- SSH (from same Wi-Fi): `ssh -p 8022 phone@<phone-ip>` — username is anything, password = Termux password (`passwd`).
- code-server (browser): `http://<phone-ip>:8080` — password in `~/.config/code-server/config.yaml`, also printed on start.

## Alex, why on Earth would you do this?

- Because.

- Modern smartphones have a bit more capable hardware than people would think. Obviously, you aren't going to replace your M5 Macbook Pro with this, buuut, I like the idea of "Hey, I can do some dev work with my phone, a usb hub, and a cheap monitor" (or connect to my phone with a Chromebook or something.)

- To attach a bit more to the second point, I suppose it's also rooted in an anxious thought of "What if I needed/wanted to do dev work, but no longer had access to a decent 'real' computer?" Having scripts like this help with that anxiety. 

## Gotchas (2026-09, code-server 4.135.0)
- `start-vscode.sh` injects `LD_PRELOAD=libtermux-exec.so` and patches VS Code's env
  sanitizer (`server-main.js`, `agentHostMain.js`, `extensionHostProcess.js` — removes
  `"LD_PRELOAD",` from the kill-list Set). Without it the terminal spawns fail with
  "execvp(3) failed.: Permission denied". The script re-applies the patch automatically
  after `pkg upgrade code-server`.
- `pkg install code-server` requires `tur-repo` (Termux User Repository).
- If the phone IP changed, just re-run a script — it prints the current one. I'd recommend using something like [tailscale](https://tailscale.com/) or [ngrok](https://ngrok.com/)if you want a static name.
- `/tmp` is not writable in Termux; logs go to `~/tmp/`.
