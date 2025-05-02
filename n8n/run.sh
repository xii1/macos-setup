#!/usr/bin/env bash

sudo tailscale funnel 5678 &

export WEBHOOK_URL=
export N8N_RUNNERS_ENABLED=true

n8n start &
