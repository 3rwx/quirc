FROM ubuntu:20.04

RUN apt-get update && apt-get install -y \
	unzip curl git zsh build-essential

RUN chsh -s $(which zsh)
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ENV ZSH_THEME=robbyrussell
