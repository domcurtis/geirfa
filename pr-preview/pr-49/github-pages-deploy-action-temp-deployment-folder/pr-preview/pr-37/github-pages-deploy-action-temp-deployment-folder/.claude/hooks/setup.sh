#!/bin/bash
if ! command -v gh &> /dev/null; then
  apt-get install -y gh 2>/dev/null || true
fi
