
FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG NODE_VERSION=22

RUN apt-get update && apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

USER vscode

RUN curl -fsSL https://get.pnpm.io/install.sh | SHELL=bash bash -

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/home/vscode/.local/bin:${PATH}"
