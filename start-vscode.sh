#!/data/data/com.termux/files/usr/bin/bash
# start-vscode.sh — run code-server (VS Code in the browser) on this phone and print how to open it.

PORT=8080
CFG=$HOME/.config/code-server/config.yaml
LOG=$HOME/tmp/code-server.log

case "$1" in
    stop)
        pkill -f '[c]ode-server' && echo "[*] code-server stopped" || echo "code-server was not running"
        command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock
        exit 0
        ;;
esac

# 1. make sure code-server is installed
if ! command -v code-server >/dev/null 2>&1; then
    echo "[*] Installing code-server (big download)..."
    pkg install -y tur-repo && pkg install -y code-server || { echo "!! install failed"; exit 1; }
fi

# 2. config: create with a random password if missing
if [ ! -f "$CFG" ]; then
    mkdir -p "$(dirname "$CFG")"
    PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24)
    printf 'bind-addr: 0.0.0.0:%s\nauth: password\npassword: %s\ncert: false\n' "$PORT" "$PASS" > "$CFG"
fi
# default config binds 127.0.0.1 (localhost only) — must listen on all interfaces for LAN access
grep -q "^bind-addr: 0.0.0.0:" "$CFG" || sed -i "s/^bind-addr:.*/bind-addr: 0.0.0.0:$PORT/" "$CFG"

# 2.5 re-apply the termux-exec fix if a code-server upgrade restored the sanitizer
CSS=$PREFIX/lib/code-server/lib/vscode/out
if [ -f "$CSS/server-main.js" ] && grep -q '"LD_PRELOAD",' "$CSS/server-main.js" 2>/dev/null; then
    echo "[*] Re-applying LD_PRELOAD sanitizer patch (code-server updated?)"
    sed -i 's/"LD_PRELOAD",//g' "$CSS/server-main.js" \
        "$CSS/vs/platform/agentHost/node/agentHostMain.js" \
        "$CSS/vs/workbench/api/node/extensionHostProcess.js" 2>/dev/null
fi

# 3. keep Termux alive when the screen turns off
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock

# 4. start detached if not already running
# termux-exec must be preloaded: without it the kernel denies shebang-script
# execve from app data (EACCES) and the integrated terminal cannot launch
if [ -z "$LD_PRELOAD" ] && [ -f "$PREFIX/lib/libtermux-exec.so" ]; then
    export LD_PRELOAD="$PREFIX/lib/libtermux-exec.so"
fi
if pgrep -f '[c]ode-server' >/dev/null 2>&1; then
    echo "[*] code-server already running"
else
    if command -v setsid >/dev/null 2>&1; then
        setsid code-server >"$LOG" 2>&1 &
    else
        nohup code-server >"$LOG" 2>&1 &
    fi
    sleep 3
    if pgrep -f '[c]ode-server' >/dev/null 2>&1; then
        echo "[*] code-server started (log: $LOG)"
    else
        echo "!! failed to start — last log lines:"
        tail -5 "$LOG" 2>/dev/null
        exit 1
    fi
fi

# 5. show connection info
IP=$(ifconfig 2>/dev/null | awk '$1=="inet" && $2!="127.0.0.1" {print $2; exit}')
PASS=$(grep '^password:' "$CFG" | awk '{print $2}')
echo
echo "== Open from another device on the same Wi-Fi =="
echo "   http://$IP:$PORT"
echo "   password: $PASS"
echo
echo "   stop the server:  ~/start-vscode.sh stop"
