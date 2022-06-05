#!/bin/bash

ext="sh"
arch="$(arch)"
case "$(uname -s)" in
    Linux*) machine=Linux;;
    Darwin*) machine=MacOSX;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*) machine=Windows && ext="exe";;
    *) echo "Error: OS $(uname -s) not supported" && exit 1;;
esac


prompt_yn() {
    while true; do
        read -p "$1 [y/n]? " -n 1 -r
        echo
        case "$REPLY" in 
            y|Y ) break;;
            n|N ) echo "exiting..." && return 1;;
            * )   : ;;
        esac
    done
}        

install_miniconda() {
    installer_name="Miniconda3-latest-$machine-$arch.$ext"

    # Download installer
    if [ ! -f "$installer_name" ]; then
        url="https://repo.anaconda.com/miniconda/$installer_name"
        file_size_bytes=$(curl -s --head "$url" | grep content-length | cut -d " " -f2 | tr -d '\r')
        prompt_yn "Download $url (~$((file_size_bytes/1000/1000))MB)"
        curl -O "$url"
        echo
    else
        prompt_yn "$installer_name present but not installed. Install"
    fi

    echo "Installing miniconda3..."
    if [[ "$machine" == 'Windows' ]]; then
        cwd=$(pwd -W | sed 's/\//\\/g')
        install_command="start /w $installer_name /InstallationType=JustMe /AddToPath=0 /RegisterPython=0 /NoRegistry /NoShortcuts /S /D=$cwd\\miniconda3"
        cmd.exe //C "$install_command"
    else
        bash "$installer_name" -b -p ./miniconda3
    fi

    echo "Successfully installed miniconda3 in $cwd/miniconda3"
    echo
}

if [ ! -f "miniconda3/etc/profile.d/conda.sh" ]; then
    echo "No miniconda installation found"
    install_miniconda
fi

# shellcheck source=/dev/null
source miniconda3/etc/profile.d/conda.sh

num_envs=$(find miniconda3/envs/ -mindepth 1 -maxdepth 1 -type d | wc -l)

if (( num_envs == 0 )); then
    echo "No conda env found"
    read -r -p "Enter new env name: " env_name

    conda create --name "$env_name"
fi

if (( num_envs > 1 )); then
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

