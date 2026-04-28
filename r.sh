#!/bin/bash
set -e
echo "=== POD INFO ==="
grep PRETTY_NAME /etc/os-release
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
echo
echo "=== APT ESSENTIALS ==="
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq tmux htop ncdu git curl ca-certificates 2>&1 | tail -3
echo
echo "=== GIT CONFIG ==="
git config --global user.email "itayspacecowboy@gmail.com"
git config --global user.name "Itay Turgeman"
git config --global init.defaultBranch main
git config --global --list | grep -E "user|init"
echo
echo "=== INSTALL UV ==="
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh 2>&1 | tail -3
fi
export PATH="$HOME/.local/bin:$PATH"
uv --version || (echo "uv install failed"; exit 1)
echo
echo "=== BRACKETED PASTE (~/.inputrc) ==="
# Enables bash readline bracketed paste so multi-line pastes survive
# terminal line-wrap (newlines in paste are treated as text, not Enter)
cat > ~/.inputrc <<'IRC'
$include /etc/inputrc
set enable-bracketed-paste on
set show-all-if-ambiguous on
set completion-ignore-case on
IRC
echo "(active in next shell — current shell needs 'bind -f ~/.inputrc')"
echo
echo "=== PERSISTENT BASHRC IN /workspace ==="
mkdir -p /workspace
cat > /workspace/.bashrc.atlas <<'BRC'
# Atlas pod profile — survives pod stops because /workspace persists
export PATH="$HOME/.local/bin:$PATH"
export PS1="\[\e[38;5;212m\]runpod\[\e[0m\]:\[\e[38;5;75m\]\w\[\e[0m\]\$ "
alias ll="ls -lah"
alias gpu="nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total --format=csv"
alias gpuw="watch -n 1 nvidia-smi"
# Re-apply bracketed paste in case shell started before ~/.inputrc existed
bind -f ~/.inputrc 2>/dev/null
cd /workspace 2>/dev/null
BRC
grep -q "workspace/.bashrc.atlas" ~/.bashrc 2>/dev/null || echo '[ -f /workspace/.bashrc.atlas ] && source /workspace/.bashrc.atlas' >> ~/.bashrc
ls -la /workspace/.bashrc.atlas ~/.inputrc
echo
echo "=== TORCH GPU CHECK ==="
python3 -c "import torch; print('torch', torch.__version__, 'cuda', torch.cuda.is_available(), torch.cuda.get_device_name(0) if torch.cuda.is_available() else '')" 2>&1 | head -2 || echo "(no torch — install per-project with uv)"
echo
echo "=== DONE ==="
