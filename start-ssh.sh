#!/data/data/com.termux/files/usr/bin/bash
# start-ssh.sh — start the Termux SSH server and print how to connect from another device.

PORT=8022

case "$1" in
    stop)
        pkill -x sshd && echo "[*] sshd stopped" || echo "sshd was not running"
        command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock
        exit 0
        ;;
esac

# 1. make sure openssh is installed
if ! command -v sshd >/dev/null 2>&1; then
    echo "[*] Installing openssh..."
    pkg install -y openssh || { echo "!! pkg install failed"; exit 1; }
fi

# 2. keep Termux alive when the screen turns off
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock

# 3. start sshd if not already running
if pgrep -x sshd >/dev/null 2>&1; then
    echo "[*] sshd already running"
else
    sshd && echo "[*] sshd started on port $PORT"
fi

# 4. a password is required to log in
HASH=$(cut -d: -f2 "$PREFIX/etc/shadow" 2>/dev/null | head -n 1)
if [ -z "$HASH" ] || [ "$HASH" = "!" ] || [ "$HASH" = "*" ]; then
    echo "[*] No password set yet — pick one now (you'll type it when connecting)."
    passwd || echo "!! passwd failed — run 'passwd' manually before connecting"
fi

# 5. show connection info
IP=$(ifconfig 2>/dev/null | awk '$1=="inet" && $2!="127.0.0.1" {print $2; exit}')
echo
echo "== Connect from another device on the same Wi-Fi =="
echo "   ssh -p $PORT phone@$IP"
echo "   (username can be anything; password = your Termux password)"
echo
echo "   stop the server:  ~/start-ssh.sh stop"
