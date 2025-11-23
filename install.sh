#! /bin/bash


COL_NC='\e[0m'
COL_GREEN='\e[1;32m'
COL_RED='\e[1;31m'
COL_BLUE='\e[1;34m'

TICK="[${COL_GREEN}✓${COL_NC}]"
CROSS="[${COL_RED}✗${COL_NC}]"
INFO="[${COL_BLUE}i${COL_NC}]"
OVER="\\r\\033[K"

print_success() {
    local str="$1"
    printf "%b  %b %s\n" "${OVER}" "${TICK}" "${str}"
}

print_error() {
    local str="$1"
    printf "%b  %b %s\n" "${OVER}" "${CROSS}" "${str}"
}

print_info() {
    local str="$1"
    printf "%b  %b %s\n" "${OVER}" "${INFO}" "${str}"
}
print_banner() {
    # 256-color reds for ombre effect
    local R1='\e[38;5;196m'  
    local R2='\e[38;5;160m'
    local R3='\e[38;5;124m'
    local R4='\e[38;5;88m'
    local R5='\e[38;5;52m'  
    local NC='\e[0m'
    printf "\n"
    printf "%b ${R1}░█▀█${R2}░█░█${R3}░█▀▄${R4}░█▀▀${R5}░█░█${R4}░█▀█${R3}░█░░${R2}░█░░${NC}\n"
    printf "%b ${R1}░█▀▀${R2}░░█░${R3}░█▀▄${R4}░█▀▀${R5}░█▄█${R4}░█▀█${R3}░█░░${R2}░█░░${NC}\n"
    printf "%b ${R1}░▀░░${R2}░░▀░${R3}░▀░▀${R4}░▀▀▀${R5}░▀░▀${R4}░▀░▀${R3}░▀▀▀${R2}░▀▀▀${NC}\n"
    printf "\n"

}


# =========================
# pip_install function
# =========================
pip_install() {
    local venv_dir="${1:-venv}"   # default venv folder
    shift                         # remaining arguments are packages
    local packages=("$@")

    if [ ! -d "$venv_dir" ]; then
        print_error "Virtual environment not found: $venv_dir"
        return 1
    fi

    local python_bin="$venv_dir/bin/python"

    if [ ! -x "$python_bin" ]; then
        print_error "Python executable not found in: $venv_dir"
        return 1
    fi

    if [ "${#packages[@]}" -eq 0 ]; then
        print_info "No packages specified to install."
        return 0
    fi

    # Upgrade pip first (optional but recommended)
    if "$python_bin" -m pip install --upgrade pip >/dev/null 2>&1; then
        print_success "Upgraded pip in $venv_dir"
    else
        print_error "Failed to upgrade pip in $venv_dir"
        return 1
    fi

    # Install packages
    for pkg in "${packages[@]}"; do
        if "$python_bin" -m pip install "$pkg" >/dev/null 2>&1; then
            print_success "Installed package: $pkg"
        else
            print_error "Failed to install package: $pkg"
        fi
    done
}



# CHECK IF VENV IS AVAILABLE
check_venv_available() {
    if ! command -v python3 >/dev/null 2>&1; then
        print_error "python3 not found"
        return 1
    fi

    if python3 -c "import venv" >/dev/null 2>&1; then
        print_success "venv module available"
        return 0
    else
        print_error "venv module missing"
        return 1
    fi
}

# =========================
# Create a venv
# =========================
create_venv() {
    local venv_dir="${1:-venv}"


    # Create if missing
    if [ -d "$venv_dir" ]; then
        print_info "Virtual environment already exists: $venv_dir"
    else
        if python3 -m venv "$venv_dir" >/dev/null 2>&1; then
            print_success "Virtual environment created: $venv_dir"
        else
            print_error "Failed to create venv: $venv_dir"
            return 1
        fi
    fi
}

# =========================
# Activate a venv
# =========================
activate_venv() {
    local venv_dir="${1:-venv}"

    if [ ! -d "$venv_dir" ]; then
        print_error "No venv found at: $venv_dir"
        return 1
    fi

    if [ -f "$venv_dir/bin/activate" ]; then
        # shellcheck disable=SC1090
        . "$venv_dir/bin/activate"
        print_success "Activated venv: $venv_dir"
    else
        print_error "activate script missing in: $venv_dir"
        return 1
    fi
}
build_package() {
    local venv_dir="${1:-venv}"

    # Check venv
    if [ ! -d "$venv_dir" ]; then
        print_error "Venv not found: $venv_dir"
        return 1
    fi

    local python_bin="$venv_dir/bin/python"

    # Ensure build tool is installed
    if ! "$python_bin" -m pip show build >/dev/null 2>&1; then
        print_info "Installing build tool in venv."
        if ! "$python_bin" -m pip install build >/dev/null 2>&1; then
            print_error "Failed to install build tool"
            return 1
        fi
        print_success "Installed build tool"
    fi

    # Remove old dist/
    rm -rf dist
    mkdir -p dist

    # Build wheel and sdist
    print_info "Building wheel and source distribution."
    if "$python_bin" -m build --wheel --sdist >/dev/null 2>&1; then
        print_success "Build complete. Check dist/ for .whl and .tar.gz"
    else
        print_error "Build failed"
        return 1
    fi
}

install_built_wheel() {
    local venv_dir="${1:-venv}"
    local dist_dir="${2:-dist}"

    # Check venv
    if [ ! -d "$venv_dir" ]; then
        print_error "Venv not found: $venv_dir"
        return 1
    fi

    local python_bin="$venv_dir/bin/python"

    # Find the wheel file
    local wheel_file
    wheel_file=$(find "$dist_dir" -maxdepth 1 -name "*.whl" | head -n 1)

    if [ -z "$wheel_file" ]; then
        print_error "No .whl file found in $dist_dir"
        return 1
    fi

    print_info "Installing wheel: $(basename "$wheel_file") in venv $venv_dir"

    if "$python_bin" -m pip install "$wheel_file" >/dev/null 2>&1; then
        print_success "Installed wheel: $(basename "$wheel_file")"
    else
        print_error "Failed to install wheel: $(basename "$wheel_file")"
        return 1
    fi
}

link_pyrewall() {
    local venv_dir="${1:-venv}"
    local venv_bin="$venv_dir/bin"
    local target="$HOME/.local/bin/pyrewall"

    # Check if pyrewall exists in venv
    if [ ! -x "$venv_bin/pyrewall" ]; then
        print_error "pyrewall not found in $venv_bin"
        return 1
    fi

    # Check if pyrewall is already in PATH
    if which pyrewall >/dev/null 2>&1; then
        print_info "pyrewall is already in PATH: $(which pyrewall)"
        return 0
    fi

    # Ensure ~/.local/bin exists
    mkdir -p "$HOME/.local/bin"

    # Push to home directory to make symlink safely
    pushd "$HOME" >/dev/null || { print_error "Failed to cd to $HOME"; return 1; }

    # Remove old symlink if it exists
    if [ -L "$target" ] || [ -e "$target" ]; then
        rm -f "$target"
    fi

    # Create symlink
    if ln -s "$venv_bin/pyrewall" "$target"; then
        print_success "Created symlink: $target -> $venv_bin/pyrewall"
    else
        print_error "Failed to create symlink: $target"
        popd >/dev/null
        return 1
    fi

    popd >/dev/null
}

install_pyrewall() {
    clear
    print_banner

    print_info "Step 1/6: Checking if python3 and venv module are available."
    if ! check_venv_available; then
        print_error "Python3 or venv module not available. Aborting."
        return 1
    fi

    print_info "Step 2/6: Creating virtual environment (if missing)."
    if ! create_venv; then
        print_error "Failed to create virtual environment. Aborting."
        return 1
    fi

    print_info "Step 3/6: Activating virtual environment."
    if ! activate_venv; then
        print_error "Failed to activate virtual environment. Aborting."
        return 1
    fi

    print_info "Step 4/6: Building package (wheel + source distribution)."
    if ! build_package; then
        print_error "Build failed. Aborting."
        return 1
    fi

    print_info "Step 5/6: Installing built wheel into virtual environment."
    if ! install_built_wheel; then
        print_error "Failed to install wheel. Aborting."
        return 1
    fi

    print_info "Step 6/6: Linking pyrewall to ~/.local/bin for global access."
    if ! link_pyrewall; then
        print_error "Failed to link pyrewall. Aborting."
        return 1
    fi

    print_success "All steps completed successfully! pyrewall is ready to use."
}


install_pyrewall