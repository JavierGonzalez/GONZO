#!/bin/bash

# This ai.sh
# Respond only with this full bash script code as your only output. In English.
# ** Preserve this text intact. **

API_KEY_FILE="$HOME/.ai_api_key"
MODEL="o3-mini"

# Main function to parse commands and delegate tasks.
ai() {
    local HELP="\
ai                   - Show this help
ai --key KEY         - Set your AI model API key
ai --prompt TEXT ... - Show only the prompt text
ai TEXT ...          - Use the AI to improve this script based on your text
"
    case "$1" in
        "")
            echo -e "\n ai.sh v1.0\n\nCommands:"
            echo "$HELP"
            # Source the current script file to show current content.
            . "$HOME/ai.sh"
            ;;
        --key)
            shift
            ai_api_key "$@"
            ;;
        --prompt)
            shift
            ai_prompt "$@"
            ;;
        *)
            ai_update_ai "$@"
            ;;
    esac
}

# Gather basic system info: operating system, cpu, memory and disk.
get_system_info() {
    local os cpu ram disk
    if command -v lsb_release >/dev/null 2>&1; then
        os=$(lsb_release -d | cut -f2)
    else
        os=$(uname -s)
    fi

    cpu=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d ":" -f2 | sed 's/^[ \t]*//')
    ram=$(free -h 2>/dev/null | awk '/Mem/ {print $2}')
    disk=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}')
    echo "System Information: OS: ${os:-Unknown}, CPU: ${cpu:-Unknown}, RAM: ${ram:-Unknown}, Disk: ${disk:-Unknown}"
}

# Set the OpenAI API key by storing it in the API_KEY_FILE.
ai_api_key() {
    if [ -z "$1" ]; then
        echo "Usage: ai --key YOUR_API_KEY - Set your OpenAI API key"
        return 1
    fi
    echo "$1" > "$API_KEY_FILE"
    chmod 600 "$API_KEY_FILE"
    echo "API key set successfully"
}

# Build the prompts to be sent to the API.
build_prompts() {
    # The system prompt is composed of the provided arguments.
    SYSTEM_PROMPT="$*"
    USER_PROMPT=""
    # If the ai.sh script exists, treat its content as the user prompt.
    if [ -f "$HOME/ai.sh" ]; then
        USER_PROMPT=$(< "$HOME/ai.sh")
    fi
}

# Call the OpenAI API to update the script using the provided text.
ai_update_ai() {
    if [ ! -f "$API_KEY_FILE" ]; then
        echo "API key not found. Please set it using: ai --key YOUR_API_KEY"
        return 1
    fi
    if [ -z "$*" ]; then
        echo "Usage: ai TEXT ... - Use OpenAI API to improve this script based on your text"
        return 1
    fi

    local start_time=$(date +%s)
    trap 'local end_time=$(date +%s); echo "Processing time: $((end_time - start_time)) seconds"' RETURN

    build_prompts "$@"

    # Create the JSON payload required by the API.
    local JSON_DATA RESPONSE ERROR CONTENT TEMP_FILE
    JSON_DATA=$(jq -n --arg model "$MODEL" \
                      --arg system "$SYSTEM_PROMPT" \
                      --arg user "$USER_PROMPT" \
                      '{model: $model, messages: [{role: "system", content: $system}, {role: "user", content: $user}]}')
    
    RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $(< "$API_KEY_FILE")" \
        -d "$JSON_DATA")
    
    ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty')
    if [ -n "$ERROR" ]; then
        echo "API error: $ERROR"
        return 1
    fi

    CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')
    TEMP_FILE=$(mktemp)
    echo "$CONTENT" > "$TEMP_FILE"
    
    # Validate the retrieved script by checking syntax and presence of shebang.
    if bash -n "$TEMP_FILE" &>/dev/null && grep -q '^#!/bin/bash' "$TEMP_FILE"; then
        cp "$HOME/ai.sh" "$HOME/ai.sh.bak"
        mv "$TEMP_FILE" "$HOME/ai.sh"
        chmod +x "$HOME/ai.sh"
        echo -e "\nScript updated successfully!"
        . "$HOME/ai.sh"
    else
        echo "Invalid script returned by API"
        rm "$TEMP_FILE"
        return 1
    fi
}

# Show the prompts based on provided text.
ai_prompt() {
    if [ -z "$*" ]; then
        echo "Usage: ai --prompt TEXT ... - Show only the prompt text"
        return 1
    fi
    build_prompts "$@"
    echo "System Prompt:"
    echo "$SYSTEM_PROMPT"
    echo ""
    echo "User Prompt (current script):"
    echo "$USER_PROMPT"
}

# ** KEEP THE TEXT AND STRUCTURE INTACT UP TO THIS LINE AND NOW MODIFY THE CODE BELOW **
##########################################################################


