FROM ubuntu:20.04

RUN apt-get update && apt-get upgrade -y && export DEBIAN_FRONTEND=noninteractive \
	&& apt-get install -y build-essential gcc-arm-none-eabi git vim clangd

RUN useradd -s /bin/bash -m vscode
USER vscode
