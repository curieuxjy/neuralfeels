#!/bin/bash -e

# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

usage="$(basename "$0") [-h] [-e ENV_NAME] [-f INSTALL_FAIROTAG] --
Install the neuralfeels environment
where:
    -h  show this help text
    -e  name of the environment, default=_neuralfeels
"

options=':he:'
while getopts $options option; do
    case "$option" in
    h)
        echo "$usage"
        exit
        ;;
    e) ENV_NAME=$OPTARG ;;
    :)
        printf "missing argument for -%s\n" "$OPTARG" >&2
        echo "$usage" >&2
        exit 1
        ;;
    \?)
        printf "illegal option: -%s\n" "$OPTARG" >&2
        echo "$usage" >&2
        exit 1
        ;;
    esac
done

# Set default environment name if not provided
if [ -z "$ENV_NAME" ]; then
    ENV_NAME=_neuralfeels
fi

echo "Environment Name: $ENV_NAME"

unset PYTHONPATH LD_LIBRARY_PATH

# Initialize the current shell for mamba
if ! mamba shell hook --help &>/dev/null; then
    echo "Mamba shell is not initialized. Please run:"
    echo "    mamba shell init --shell bash --root-prefix=~/.local/share/mamba"
    exit 1
fi

eval "$(mamba shell hook --shell bash)"

# Check if environment exists before attempting to remove it
if mamba env list | grep -q -E "^\s*$ENV_NAME\s"; then
    echo "Removing existing environment: $ENV_NAME"
    mamba remove -y -n "$ENV_NAME" --all
else
    echo "Environment $ENV_NAME does not exist. Proceeding with creation."
fi

# Create a new environment
if ! mamba env create -y --name "$ENV_NAME" --file environment_m.yml; then
    echo "Failed to create the environment from environment_m.yml"
    exit 1
fi

# Activate the environment
mamba activate "$ENV_NAME"

# Upgrade pip and install dependencies
python -m pip install --upgrade pip
pip uninstall -y torch torchvision functorch tinycudann
pip install torch==2.1.2+cu118 torchvision==0.16.2+cu118 --extra-index-url https://download.pytorch.org/whl/cu118
mamba install -y -c "nvidia/label/cuda-11.8.0" cuda-toolkit

# Verify PyTorch CUDA installation
if ! python -c "import torch; assert torch.cuda.is_available()"; then
    echo "PyTorch CUDA is not available. Check installation."
    exit 1
fi

if ! nvcc --version &>/dev/null; then
    echo "nvcc is not installed or not in PATH."
    exit 1
else
    echo "nvcc is installed and working."
fi

# Install additional dependencies
pip install ninja \
    git+https://github.com/NVlabs/tiny-cuda-nn/#subdirectory=bindings/torch \
    git+https://github.com/facebookresearch/segment-anything.git \
    git+https://github.com/suddhu/tacto.git@master

mamba install -y suitesparse
pip install theseus-ai

# Install neuralfeels package
pip install -e .

# Make scripts executable
chmod +x scripts/run
