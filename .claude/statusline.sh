#!/bin/bash

# Simple, reliable Claude Code Status Line
# Focus on working information only

# Read JSON input
input=$(cat)

# Extract basic data from JSON (with fallbacks)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // "/"' 2>/dev/null || pwd)
model_name=$(echo "$input" | jq -r '.model.display_name // ""' 2>/dev/null || echo "")

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'

# Get current time
current_time=$(date '+%H:%M:%S')

# Get current directory name
current_dir=$(basename "$cwd")

# Get git information (simple)
git_info=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || echo "detached")

    # Get simple status counts
    status_output=$(git -C "$cwd" status --porcelain 2>/dev/null || echo "")
    if [ -n "$status_output" ]; then
        changed=$(echo "$status_output" | wc -l | tr -d ' ')
        git_info="${MAGENTA}${branch}${RESET} ${YELLOW}(${changed})${RESET}"
    else
        git_info="${MAGENTA}${branch}${RESET}"
    fi
fi

# Python environment info (simple)
python_info=""
if [ -n "$VIRTUAL_ENV" ]; then
    venv_name=$(basename "$VIRTUAL_ENV")
    python_info="${GREEN}(${venv_name})${RESET}"
elif [ -n "$CONDA_DEFAULT_ENV" ] && [ "$CONDA_DEFAULT_ENV" != "base" ]; then
    python_info="${GREEN}(${CONDA_DEFAULT_ENV})${RESET}"
fi

# Build status line parts
parts=()

# Current directory
parts+=("${BLUE}${current_dir}${RESET}")

# Git info
[ -n "$git_info" ] && parts+=("${git_info}")

# Python environment
[ -n "$python_info" ] && parts+=("${python_info}")

# Claude model (only if detected)
if [ -n "$model_name" ] && [ "$model_name" != "null" ]; then
    # Shorten common model names for display
    case "$model_name" in
        *"Claude 3.5 Sonnet"*) model_display="3.5 Sonnet" ;;
        *"Claude 3 Opus"*) model_display="3 Opus" ;;
        *"Claude 3 Haiku"*) model_display="3 Haiku" ;;
        *"Sonnet 4"*) model_display="Sonnet 4" ;;
        *) model_display="$model_name" ;;
    esac
    parts+=("${WHITE}${model_display}${RESET}")
fi

# Time
parts+=("${CYAN}${current_time}${RESET}")

# Join parts with " | "
status_line=""
for i in "${!parts[@]}"; do
    if [ $i -eq 0 ]; then
        status_line="${parts[i]}"
    else
        status_line+=" ${WHITE}|${RESET} ${parts[i]}"
    fi
done

# Output the status line
printf "%b\n" "$status_line"