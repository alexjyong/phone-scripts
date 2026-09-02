#!/data/data/com.termux/files/usr/bin/bash
# setup.sh — full restore on a fresh Termux: install everything and place the scripts.
set -e

echo "[*] Installing openssh (SSH server, port 8022)..."
pkg install -y openssh

echo "[*] Installing termux-exec (required for the code-server terminal fix)..."
pkg install -y termux-exec

echo "[*] Installing tur-repo + code-server (big download, keep screen on)..."
pkg install -y tur-repo
pkg install -y code-server

echo "[*] Installing scripts..."
cp -v "$(dirname "$0")/start-ssh.sh"    "$HOME/"
cp -v "$(dirname "$0")/start-vscode.sh" "$HOME/"
chmod +x "$HOME/start-ssh.sh" "$HOME/start-vscode.sh"

echo
echo "[*] Done. Start services with:"
echo "      ~/start-ssh.sh      (SSH:   ssh -p 8022 anything@<phone-ip>)"
echo "      ~/start-vscode.sh   (code-server: http://<phone-ip>:8080)"
