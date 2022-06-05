#!/bin/bash

# ensure script is sourced
if ! (return 0 2>/dev/null); then
    echo "Error: script must be sourced"
    echo
    echo "      run '. $0' or 'source $0'"
    exit 1
fi

ext="sh"
arch="$(arch)"
case "$(uname -s)" in
    Linux*) machine=Linux ;;
    Darwin*) machine=MacOSX ;;
    CYGWIN* | MINGW32* | MSYS* | MINGW*) machine=Windows && ext="exe" ;;
    *) echo "Error: OS $(uname -s) not supported" && return 1 ;;
esac

prompt_yn() {
    while true; do
        read -p "$1 [y/n]? " -n 1 -r
        echo
        echo
        case "$REPLY" in
            y | Y) return 0 ;;
            n | N) return 1 ;;
            *) : ;;
        esac
    done
}

if [ ! -f "miniconda3/etc/profile.d/conda.sh" ]; then
    echo "No miniconda installation found"
    installer_name="Miniconda3-latest-$machine-$arch.$ext"

    # Download installer
    if [ ! -f "$installer_name" ]; then
        url="https://repo.anaconda.com/miniconda/$installer_name"
        file_size_bytes=$(curl -s --head "$url" | grep content-length | cut -d " " -f2 | tr -d '\r')
        if ! prompt_yn "Download installer from $url (~$((file_size_bytes / 1000 / 1000))MB)"; then echo "exiting..." && return 1; fi
        curl -O "$url"
        echo
        if ! prompt_yn "Keep $installer_name on disk"; then delete_installer=true; fi
    else
        if ! prompt_yn "$installer_name present but not installed. Install"; then echo "exiting..." && return 1; fi
    fi

    echo "Installing miniconda3..."
    if [[ $machine == 'Windows' ]]; then
        cwd=$(pwd -W | sed 's/\//\\/g')
        install_command="start /w $installer_name /InstallationType=JustMe /AddToPath=0 /RegisterPython=0 /NoRegistry /NoShortcuts /S /D=$cwd\\miniconda3"
        cmd.exe //C "$install_command"
    else
        bash "$installer_name" -b -p ./miniconda3
    fi

    echo "Successfully installed miniconda3 in $cwd/miniconda3"

    if [ "$delete_installer" = true ]; then
        rm "$installer_name"
        echo "deleted $installer_name"
    fi

    echo

fi

# shellcheck source=/dev/null
source miniconda3/etc/profile.d/conda.sh

num_envs=$(find miniconda3/envs/ -mindepth 1 -maxdepth 1 -type d | wc -l)

if ((num_envs == 0)); then
    echo "No conda env found"
    read -r -p "Enter new env name: " env_name

    conda create --name "$env_name"
fi

if ((num_envs > 1)); then
    envs="$(cd miniconda3/envs && echo */ | tr '/' ',' | sed 's/.$//' && cd ../../)"
    echo "Multiple conda envs found ($envs)"
    while true; do
        read -r -p "Enter desired env: " raw_env
        if [[ $envs == *"$raw_env"* ]]; then
            env_name="$raw_env"
            break
        else
            echo "Error: $raw_env not in $envs"
        fi
    done
fi

echo "Activating $env_name.."
conda activate "$env_name"
