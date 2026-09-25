#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# Reviactyl / Pterodactyl Node Installer
#
# ใช้สำหรับ:
#   - Ubuntu Node เครื่องใหม่
#   - มี config.yml จาก Panel หลักแล้ว
#   - ติดตั้ง Docker
#   - ติดตั้ง Wings
#   - เลือกตำแหน่งเก็บ Server/Container data
#   - สร้าง systemd service
#   - Start Wings
#
# Usage:
#   chmod +x install-node.sh
#   sudo ./install-node.sh
#
# ============================================================

SCRIPT_VERSION="1.0.0"

WINGS_BIN="/usr/local/bin/wings"
PTERO_DIR="/etc/pterodactyl"
CONFIG_FILE="${PTERO_DIR}/config.yml"
SERVICE_FILE="/etc/systemd/system/wings.service"

DEFAULT_ROOT="/var/lib/pterodactyl"

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

info() {
    echo -e "${BLUE}[INFO]${RESET} $*"
}

success() {
    echo -e "${GREEN}[ OK ]${RESET} $*"
}

warning() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $*"
}

die() {
    error "$*"
    exit 1
}

pause() {
    echo
    read -r -p "Press ENTER to continue..."
}

# ------------------------------------------------------------
# Root
# ------------------------------------------------------------

check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        die "กรุณารันด้วย root หรือ sudo"
    fi
}

# ------------------------------------------------------------
# OS
# ------------------------------------------------------------

check_os() {

    if [[ ! -f /etc/os-release ]]; then
        die "ไม่พบ /etc/os-release"
    fi

    # shellcheck disable=SC1091
    source /etc/os-release

    OS_ID="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-unknown}"
    OS_NAME="${PRETTY_NAME:-${ID} ${VERSION_ID}}"

    if [[ "${OS_ID}" != "ubuntu" ]]; then
        warning "Script นี้ออกแบบมาสำหรับ Ubuntu"
        echo
        echo "Detected:"
        echo "  ${OS_NAME}"
        echo

        read -r -p "ต้องการดำเนินการต่อหรือไม่? [y/N]: " answer

        if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# ------------------------------------------------------------
# Architecture
# ------------------------------------------------------------

check_architecture() {

    ARCH="$(uname -m)"

    case "${ARCH}" in

        x86_64)
            WINGS_ARCH="amd64"
            ;;

        aarch64|arm64)
            WINGS_ARCH="arm64"
            ;;

        *)
            die "Architecture ${ARCH} ยังไม่รองรับ"
            ;;

    esac

    success "Architecture: ${ARCH}"
}

# ------------------------------------------------------------
# System information
# ------------------------------------------------------------

show_system_info() {

    echo
    echo "======================================================"
    echo " Reviactyl / Pterodactyl Node Installer"
    echo "======================================================"
    echo
    echo "OS          : ${OS_NAME}"
    echo "Hostname    : $(hostname)"
    echo "Architecture: ${ARCH}"
    echo "Kernel      : $(uname -r)"
    echo
}

# ------------------------------------------------------------
# Docker
# ------------------------------------------------------------

install_docker() {

    echo
    echo "======================================================"
    echo " Docker"
    echo "======================================================"
    echo

    if command -v docker >/dev/null 2>&1; then

        success "พบ Docker แล้ว"

        docker --version

        systemctl enable docker >/dev/null 2>&1 || true
        systemctl start docker

        if systemctl is-active --quiet docker; then
            success "Docker service: RUNNING"
        else
            die "Docker service ไม่สามารถ start ได้"
        fi

        return
    fi

    info "ไม่พบ Docker"
    info "กำลังติดตั้ง Docker..."

    apt-get update

    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    curl -fsSL https://get.docker.com | sh

    systemctl enable docker
    systemctl start docker

    if ! command -v docker >/dev/null 2>&1; then
        die "ติดตั้ง Docker ไม่สำเร็จ"
    fi

    if ! systemctl is-active --quiet docker; then
        die "Docker service ไม่ทำงาน"
    fi

    success "ติดตั้ง Docker สำเร็จ"

    docker --version
}

# ------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------

install_dependencies() {

    info "ติดตั้ง dependencies..."

    apt-get update

    apt-get install -y \
        curl \
        ca-certificates \
        tar \
        unzip \
        jq \
        nano

    success "Dependencies พร้อมใช้งาน"
}

# ------------------------------------------------------------
# Storage
# ------------------------------------------------------------

detect_mounts() {

    echo
    echo "======================================================"
    echo " Available Storage"
    echo "======================================================"
    echo

    df -hT \
        --exclude-type=tmpfs \
        --exclude-type=devtmpfs \
        --exclude-type=overlay \
        | awk '
        NR==1 {
            printf "%-25s %-10s %-12s %-12s %-8s\n",
            "Mount", "Type", "Size", "Available", "Used"
            next
        }
        {
            printf "%-25s %-10s %-12s %-12s %-8s\n",
            $7, $2, $3, $5, $6
        }'

    echo
}

choose_storage() {

    echo
    echo "======================================================"
    echo " Server Storage"
    echo "======================================================"
    echo

    echo "กำหนดตำแหน่งที่จะเก็บ Minecraft/Game Server data"
    echo
    echo "ตัวอย่าง:"
    echo "  /var/lib/pterodactyl"
    echo "  /data/pterodactyl"
    echo "  /mnt/games/pterodactyl"
    echo

    detect_mounts

    read -r -p "Storage path [${DEFAULT_ROOT}]: " STORAGE_PATH

    if [[ -z "${STORAGE_PATH}" ]]; then
        STORAGE_PATH="${DEFAULT_ROOT}"
    fi

    # Convert relative path to absolute.
    if [[ "${STORAGE_PATH}" != /* ]]; then
        die "Storage path ต้องเป็น absolute path"
    fi

    echo
    echo "Selected storage:"
    echo
    echo "  ${STORAGE_PATH}"
    echo

    read -r -p "ยืนยัน path นี้หรือไม่? [Y/n]: " confirm

    if [[ "${confirm}" =~ ^[Nn]$ ]]; then
        choose_storage
        return
    fi

    mkdir -p "${STORAGE_PATH}"

    success "สร้าง storage directory แล้ว"

    STORAGE_PATH="$(realpath "${STORAGE_PATH}")"

    echo
    echo "Final storage path:"
    echo "  ${STORAGE_PATH}"
}

# ------------------------------------------------------------
# Pterodactyl directories
# ------------------------------------------------------------

prepare_directories() {

    echo
    info "เตรียม directories..."

    mkdir -p "${PTERO_DIR}"
    mkdir -p "${STORAGE_PATH}"

    chmod 755 "${PTERO_DIR}"
    chmod 755 "${STORAGE_PATH}"

    success "Directories พร้อมใช้งาน"
}

# ------------------------------------------------------------
# Config
# ------------------------------------------------------------

copy_config() {

    echo
    echo "======================================================"
    echo " Node Configuration"
    echo "======================================================"
    echo

    if [[ -f "${CONFIG_FILE}" ]]; then

        warning "พบ config เดิม:"
        echo
        echo "  ${CONFIG_FILE}"
        echo

        read -r -p "ต้องการ overwrite หรือไม่? [y/N]: " overwrite

        if [[ ! "${overwrite}" =~ ^[Yy]$ ]]; then
            success "ใช้ config เดิม"
            return
        fi
    fi

    echo "เลือกวิธีใส่ config:"
    echo
    echo "  1) ระบุ path ของ config.yml"
    echo "  2) Paste config จาก Panel"
    echo

    read -r -p "เลือก [1-2]: " method

    case "${method}" in

        1)

            read -r -p "Path ของ config.yml: " SOURCE_CONFIG

            if [[ ! -f "${SOURCE_CONFIG}" ]]; then
                die "ไม่พบไฟล์ ${SOURCE_CONFIG}"
            fi

            cp "${SOURCE_CONFIG}" "${CONFIG_FILE}"

            ;;

        2)

            echo
            echo "=============================================="
            echo " Paste config.yml"
            echo "=============================================="
            echo
            echo "นำ Configuration จาก Panel หลักมา paste"
            echo
            echo "เสร็จแล้วกด CTRL+D"
            echo

            cat > "${CONFIG_FILE}"

            ;;

        *)

            die "ตัวเลือกไม่ถูกต้อง"

            ;;

    esac

    chmod 600 "${CONFIG_FILE}"
    chown root:root "${CONFIG_FILE}"

    if [[ ! -s "${CONFIG_FILE}" ]]; then
        die "config.yml ว่าง"
    fi

    success "ติดตั้ง config.yml แล้ว"
}

# ------------------------------------------------------------
# Change root directory in config
# ------------------------------------------------------------

configure_root_directory() {

    echo
    echo "======================================================"
    echo " Configure Root Directory"
    echo "======================================================"
    echo

    echo "Storage ที่เลือก:"
    echo
    echo "  ${STORAGE_PATH}"
    echo

    warning "ขั้นตอนนี้จะพยายามแก้ root_directory ใน config.yml"
    echo

    if grep -q "root_directory:" "${CONFIG_FILE}"; then

        sed -i \
            -E "s|^[[:space:]]*root_directory:.*|  root_directory: ${STORAGE_PATH}|" \
            "${CONFIG_FILE}"

        success "ตั้ง root_directory เป็น:"
        echo "  ${STORAGE_PATH}"

    else

        warning "ไม่พบ root_directory ใน config.yml"
        warning "จะไม่แก้ config อัตโนมัติ"
        warning "ตรวจสอบ config ของ Reviactyl/Wings ด้วยตัวเอง"

    fi
}

# ------------------------------------------------------------
# Install Wings
# ------------------------------------------------------------

install_wings() {

    echo
    echo "======================================================"
    echo " Wings"
    echo "======================================================"
    echo

    if [[ -x "${WINGS_BIN}" ]]; then

        success "พบ Wings อยู่แล้ว"

        "${WINGS_BIN}" --version 2>/dev/null || true

        read -r -p "ต้องการดาวน์โหลด Wings ใหม่หรือไม่? [y/N]: " update

        if [[ ! "${update}" =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    info "กำลังดาวน์โหลด Wings..."

    # --------------------------------------------------------
    # Official Pterodactyl Wings release
    # --------------------------------------------------------

    WINGS_VERSION="$(curl -fsSL \
        https://api.github.com/repos/pterodactyl/wings/releases/latest \
        | jq -r '.tag_name')"

    if [[ -z "${WINGS_VERSION}" || "${WINGS_VERSION}" == "null" ]]; then
        die "ไม่สามารถหา Wings latest version ได้"
    fi

    info "Wings version: ${WINGS_VERSION}"

    DOWNLOAD_URL="https://github.com/pterodactyl/wings/releases/download/${WINGS_VERSION}/wings_linux_${WINGS_ARCH}"

    curl -fL \
        --retry 5 \
        --retry-delay 2 \
        -o "${WINGS_BIN}" \
        "${DOWNLOAD_URL}"

    chmod 755 "${WINGS_BIN}"

    if [[ ! -x "${WINGS_BIN}" ]]; then
        die "Wings installation failed"
    fi

    success "ติดตั้ง Wings สำเร็จ"

    "${WINGS_BIN}" --version 2>/dev/null || true
}

# ------------------------------------------------------------
# systemd
# ------------------------------------------------------------

create_service() {

    echo
    info "สร้าง wings.service..."

    cat > "${SERVICE_FILE}" <<'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
RestartSec=5s
StartLimitInterval=180
StartLimitBurst=30

[Install]
WantedBy=multi-user.target
EOF

    chmod 644 "${SERVICE_FILE}"

    mkdir -p /var/run/wings

    systemctl daemon-reload
    systemctl enable wings

    success "สร้าง systemd service แล้ว"
}

# ------------------------------------------------------------
# Firewall
# ------------------------------------------------------------

firewall_info() {

    echo
    echo "======================================================"
    echo " Firewall"
    echo "======================================================"
    echo

    if command -v ufw >/dev/null 2>&1; then

        echo "UFW detected:"
        ufw status || true

        echo
        warning "ตรวจสอบ port ของ Wings และ Minecraft allocations"
        warning "ให้ตรงกับที่ตั้งไว้ใน Reviactyl Panel"

    elif command -v firewall-cmd >/dev/null 2>&1; then

        echo "firewalld detected:"
        firewall-cmd --state || true

        echo
        warning "ตรวจสอบ port ของ Wings และ Minecraft allocations"

    else

        warning "ไม่พบ UFW/firewalld"
        warning "ตรวจสอบ firewall ของ VPS/Provider ด้วย"

    fi
}

# ------------------------------------------------------------
# Start Wings
# ------------------------------------------------------------

start_wings() {

    echo
    echo "======================================================"
    echo " Starting Wings"
    echo "======================================================"
    echo

    systemctl daemon-reload

    systemctl restart wings

    sleep 3

    if systemctl is-active --quiet wings; then

        success "Wings is RUNNING"

    else

        error "Wings ไม่สามารถ start ได้"

        echo
        echo "========== Wings Status =========="
        systemctl status wings --no-pager -l || true

        echo
        echo "========== Wings Logs =========="
        journalctl -u wings -n 80 --no-pager -l || true

        return 1
    fi
}

# ------------------------------------------------------------
# Status
# ------------------------------------------------------------

show_status() {

    echo
    echo "======================================================"
    echo " Node Status"
    echo "======================================================"
    echo

    echo "Hostname:"
    echo "  $(hostname)"
    echo

    echo "OS:"
    echo "  ${OS_NAME}"
    echo

    echo "Architecture:"
    echo "  ${ARCH}"
    echo

    echo "Docker:"
    if command -v docker >/dev/null 2>&1; then
        docker --version
        echo "  Service: $(systemctl is-active docker || true)"
    else
        echo "  NOT INSTALLED"
    fi

    echo
    echo "Wings:"
    if [[ -x "${WINGS_BIN}" ]]; then
        "${WINGS_BIN}" --version 2>/dev/null || true
        echo "  Service: $(systemctl is-active wings || true)"
        echo "  Enabled: $(systemctl is-enabled wings || true)"
    else
        echo "  NOT INSTALLED"
    fi

    echo
    echo "Config:"
    if [[ -f "${CONFIG_FILE}" ]]; then
        echo "  ${CONFIG_FILE}"
    else
        echo "  NOT FOUND"
    fi

    echo
    echo "Server Storage:"
    echo "  ${STORAGE_PATH:-unknown}"

    echo
    echo "Disk:"
    df -h "${STORAGE_PATH:-/}" 2>/dev/null || true

    echo
}

# ------------------------------------------------------------
# Logs
# ------------------------------------------------------------

show_logs() {

    echo
    echo "======================================================"
    echo " Wings Logs"
    echo "======================================================"
    echo

    journalctl -u wings -n 100 --no-pager -l
}

# ------------------------------------------------------------
# Main installation
# ------------------------------------------------------------

install_node() {

    clear 2>/dev/null || true

    show_system_info

    echo
    read -r -p "เริ่มติดตั้ง Node บนเครื่องนี้หรือไม่? [Y/n]: " confirm

    if [[ "${confirm}" =~ ^[Nn]$ ]]; then
        exit 0
    fi

    install_dependencies

    install_docker

    choose_storage

    prepare_directories

    copy_config

    configure_root_directory

    install_wings

    create_service

    firewall_info

    start_wings

    echo
    echo "======================================================"
    echo " Installation Complete"
    echo "======================================================"
    echo

    show_status

    echo
    echo "ถ้า Panel ขึ้น Node เป็น Online = พร้อมใช้งาน"
    echo
    echo "ดู log:"
    echo "  journalctl -u wings -f"
    echo
}

# ------------------------------------------------------------
# Menu
# ------------------------------------------------------------

menu() {

    while true; do

        clear 2>/dev/null || true

        echo "======================================================"
        echo "       Reviactyl / Pterodactyl Node Installer"
        echo "                    v${SCRIPT_VERSION}"
        echo "======================================================"
        echo

        echo "OS          : ${OS_NAME}"
        echo "Hostname    : $(hostname)"
        echo "Architecture: ${ARCH}"
        echo

        echo "  1) Install Node"
        echo "  2) Check Status"
        echo "  3) Restart Wings"
        echo "  4) View Wings Logs"
        echo "  5) Start Wings"
        echo "  6) Stop Wings"
        echo "  7) Reinstall Wings"
        echo "  0) Exit"
        echo

        read -r -p "เลือกเมนู [0-7]: " choice

        case "${choice}" in

            1)
                install_node
                pause
                ;;

            2)
                show_status
                pause
                ;;

            3)
                systemctl restart wings
                success "Wings restarted"
                pause
                ;;

            4)
                show_logs
                pause
                ;;

            5)
                systemctl start wings
                success "Wings started"
                pause
                ;;

            6)
                systemctl stop wings
                success "Wings stopped"
                pause
                ;;

            7)
                install_wings
                systemctl restart wings || true
                pause
                ;;

            0)
                echo
                echo "Bye!"
                exit 0
                ;;

            *)
                warning "เมนูไม่ถูกต้อง"
                sleep 1
                ;;

        esac

    done
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {

    check_root
    check_os
    check_architecture

    menu
}

main "$@"
