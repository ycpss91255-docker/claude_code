#!/usr/bin/env bash
# i18n.sh - Shared i18n helpers for Docker scripts
#
# Sourced by: build.sh, run.sh, exec.sh, stop.sh, setup.sh
#
# Provides:
#   _detect_lang   — detect language from $LANG env var
#                    output: "zh" | "zh-CN" | "ja" | "en"
#
# After sourcing, _LANG is set (caller can override via SETUP_LANG env var).

_detect_lang() {
  local _sys_lang="${LANG:-}"
  case "${_sys_lang}" in
    zh_TW*) echo "zh" ;;
    zh_CN*|zh_SG*) echo "zh-CN" ;;
    ja*) echo "ja" ;;
    *) echo "en" ;;
  esac
}

_LANG="${SETUP_LANG:-$(_detect_lang)}"
