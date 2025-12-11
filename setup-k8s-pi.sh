#!/usr/bin/env bash
set -euo pipefail

### CONFIG ###
# Default Pod CIDR (works for Flannel)
POD_CIDR="${POD_CIDR:-10.244.0.0/16}"

# Kubernetes version repo (v1.30 stable at time of writing)
K8S_REPO_URL="https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key"

### FUNCTIONS ###

log() {
  echo -e "[INFO] $*"
}

err() {
  echo -e "[ERROR] $*" >&2
  exit 1
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    err "Run this script as root (sudo ./setup-k8s-pi.sh ...)"
  fi
}

disable_swap() {
  log "Disabling swap..."
  swapoff -a || true

  if grep -q " swap " /etc/fstab; then
    sed -i.bak '/ swap / s/^/#/' /etc/fstab
    log "Commented swap entries in /etc/fstab (backup at /etc/fstab.bak)"
  fi

  if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-unit-files | grep -q dphys-swapfile.service; then
      log "Disabling dphys-swapfile.service (Raspberry Pi default swap)..."
      systemctl disable --now dphys-swapfile.service || true
    fi
  fi
}

configure_kernel_modules() {
  log "Configuring kernel modules..."

  cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

  modprobe overlay || true
  modprobe br_netfilter || true

  cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

  sysctl --system
}

install_containerd() {
  log "Installing containerd..."
  apt-get update
  apt-get install -y containerd

  mkdir -p /etc/containerd
  containerd config default >/etc/containerd/config.toml

  # Enable systemd cgroup driver
  sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml || true

  systemctl restart containerd
  systemctl enable containerd
}

install_kubernetes_binaries() {
  log "Installing kubeadm, kubelet, kubectl..."

  mkdir -p /etc/apt/keyrings

  curl -fsSL "${K8S_REPO_URL}" \
    | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /
EOF

  apt-get update
  apt-get install -y kubelet kubeadm kubectl
  apt-mark hold kubelet kubeadm kubectl

  systemctl enable kubelet
}

detect_ip() {
  # Try to detect node's primary IP
  ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}'
}

init_master() {
  local master_ip="${MASTER_IP:-}"

  if [[ -z "${master_ip}" ]]; then
    master_ip="$(detect_ip)"
    log "MASTER_IP not set, detected IP: ${master_ip}"
  else
    log "Using provided MASTER_IP=${master_ip}"
  fi

  if [[ -z "${master_ip}" ]]; then
    err "Could not determine MASTER_IP. Set MASTER_IP env var and retry."
  fi

  log "Running kubeadm init..."
  kubeadm init \
    --apiserver-advertise-address="${master_ip}" \
    --pod-network-cidr="${POD_CIDR}" \
      --cri-socket unix:///run/containerd/containerd.sock

  log "Configuring kubectl for current user..."
  mkdir -p "$HOME/.kube"
  cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
  chown "$(id -u):$(id -g)" "$HOME/.kube/config"

  log "Installing Flannel CNI..."
  # You can switch CNI later if you want
  kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

  log "Cluster initialized. Current nodes:"
  kubectl get nodes -o wide

  log "Generating join command for workers:"
  kubeadm token create --print-join-command
}

join_worker() {
  # JOIN_COMMAND should be the full kubeadm join command
  local join_cmd="${JOIN_COMMAND:-}"

  if [[ -z "${join_cmd}" ]]; then
    err "JOIN_COMMAND environment variable is empty. Example:
  sudo JOIN_COMMAND=\"kubeadm join 10.0.0.50:6443 --token ... --discovery-token-ca-cert-hash sha256:...\" ./setup-k8s-pi.sh worker"
  fi

  log "Running worker join command..."
  # shellcheck disable=SC2086
  ${join_cmd}
}

### MAIN ###

usage() {
  cat <<EOF
Usage: sudo $0 <role>

Roles:
  master   Prepare node and initialize Kubernetes control-plane
  worker   Prepare node and join existing cluster (requires JOIN_COMMAND env)

Examples:

  # On master node:
  sudo MASTER_IP=10.0.0.50 POD_CIDR=10.244.0.0/16 ./setup-k8s-pi.sh master

  # After master prints join command, on each worker:
  sudo JOIN_COMMAND="kubeadm join 10.0.0.50:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>" \\
       ./setup-k8s-pi.sh worker
EOF
}

main() {
  require_root

  local role="${1:-}"
  if [[ -z "${role}" ]]; then
    usage
    exit 1
  fi

  log "Starting setup for role: ${role}"

  disable_swap
  configure_kernel_modules
  install_containerd
  install_kubernetes_binaries

  case "${role}" in
    master)
      init_master
      ;;
    worker)
      join_worker
      ;;
    *)
      err "Unknown role: ${role}"
      ;;
  esac

  log "Done."
}

main "$@"

