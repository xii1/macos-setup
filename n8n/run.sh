#!/usr/bin/env bash

sudo tailscale funnel --bg 5678

export WEBHOOK_URL=
export N8N_RUNNERS_ENABLED=true

n8n start &

# using pm2
# add WEBHOOK_URL and N8N_RUNNERS_ENABLED envs to ~/.bashrc
# pm2 start n8n --name n8n
# pm2 list
# pm2 save
# pm2 startup
