#!/bin/bash

tmux new -d -s irc 'docker run -it \
			-e TERM -u $(id -u):$(id -g) \
			--log-driver=none \
			-v irclogs:/home/user/irclogs \
			-v $HOME/.irssi:/home/user/.irssi:ro \
			-v /etc/localtime:/etc/localtime:ro \
			jess/irssi'
