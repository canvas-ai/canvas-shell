#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

# Source common.sh from the same directory
source "${SCRIPT_DIR}/../lib/common.sh"


##
# Canvas Context CLI
##


#########################################
# Canvas REST API bash wrapper          #
#########################################

# Help / usage message
function context_usage() {
    echo "Usage: context <command> [arguments]"
    echo "Commands:"
    echo "  list              List all available contexts"
    echo "  switch <id>       Switch to a different context"
    echo "  set <url>         Set the context URL"
    echo "  create <name>     Create a new context with optional parameters"
    echo "                    --description <text> --color <value>"
    echo "  destroy <id>      Delete a context"
    echo ""
    echo "  url               Get the current context URL"
    echo "  base-url          Get the base URL for the current context"
    echo "  path              Get the current context path"
    echo "  paths             Get all available context paths"
    echo "  tree              Get the context tree"
    echo "  workspace         Get the context workspace"
    echo ""
    echo "  note add <content> Add a note with optional parameters"
    echo "                    --title <title> --tags <tag1,tag2> --path <filepath>"
    echo "  notes             List all notes in the current context"
    echo "  tabs              List all tabs in the current context"
    echo "  tab add <url>     Add a tab with optional parameters"
    echo "                    --title <title> -t <tag1> -t <tag2>"
    echo ""
    echo "  help              Show this help message"
    echo ""
}

#########################################
# Module commands                      #
#########################################

# List all contexts
function context_list() {
    local raw="false"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --raw)
                raw="true"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    canvas_http_get "/contexts" "" "$raw"
}

# Switch to a different context
function context_switch() {
    # TODO: First list all existing contexts

    local context_id="$1"

    if [ -z "$context_id" ]; then
        echo "Error: Missing context ID"
        return 1
    fi

    # Store the new context ID in the session
    store_value "$CANVAS_SESSION" "context_id" "$context_id"
    echo "Switched to context: $context_id"

    # Update the prompt
    canvas_update_prompt
}

# Set context URL
function context_set() {
    local url="$1"
    local context_id=$(get_value "$CANVAS_SESSION" "context_id")

    if [ -z "$url" ]; then
        echo "Error: Missing URL"
        return 1
    fi

    local data="{\"url\": \"$url\"}"
    local response
    response=$(canvas_http_post "/contexts/$context_id/url" "$data" "true")

    if [ $? -eq 0 ]; then
        # Update PS1 after successful URL change
        canvas_update_prompt
    fi

    echo "$response" | jq .
}

# Create a new context
function context_create() {
    local name="$1"
    shift

    if [ -z "$name" ]; then
        echo "Error: Missing context name"
        return 1
    fi

    local description=""
    local color=""

    # Parse optional parameters
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --description)
                description="$2"
                shift 2
                ;;
            --color)
                color="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Build the request data
    local data="{\"name\": \"$name\""

    if [ -n "$description" ]; then
        data="$data, \"description\": \"$description\""
    fi

    if [ -n "$color" ]; then
        data="$data, \"color\": \"$color\""
    fi

    data="$data}"

    canvas_http_post "/contexts" "$data" | jq .
}

# Delete a context
function context_destroy() {
    local context_id="$1"

    if [ -z "$context_id" ]; then
        echo "Error: Missing context ID"
        return 1
    fi

    canvas_http_delete "/contexts/$context_id" | jq .
}

#########################################
# Getters                               #
#########################################

# Get context URL
function context_url() {
    local context_id=$(get_value "$CANVAS_SESSION" "context_id")
    local raw="false"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --raw)
                raw="true"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    canvas_http_get "/contexts/$context_id/url" "" "$raw"
}

# Get context base URL
function context_base_url() {
    local context_id=$(get_value "$CANVAS_SESSION" "context_id")
    local raw="false"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --raw)
                raw="true"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    canvas_http_get "/contexts/$context_id/base_url" "" "$raw"
}

# Get context path
function context_path() {
    local context_id=$(get_value "$CANVAS_SESSION" "context_id")
    local raw="false"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --raw)
                raw="true"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    if [ "$raw" = "true" ]; then
        canvas_http_get "/contexts/$context_id/path" "" "$raw"
    else
        canvas_http_get "/contexts/$context_id/path" "" "$raw" | jq -r '.path'
    fi
}

# Get context paths
function context_paths() {
    local context_id=$(get_value "$CANVAS_SESSION" "context_id")
    local raw="false"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --raw)
                raw="true"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    canvas_http_get "/contexts/$context_id/paths_array" "" "$raw"
}

# Get context tree
function context_tree() {
    local context_id=$(get_value "$CANVAS_SESSION" "context_id")
    local raw="false"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --raw)
                raw="true"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    canvas_http_get "/contexts/$context_id/tree" "" "$raw"
}

# Get context workspace
function context_workspace() {
    local context_id=$(get_value "$CANVAS_SESSION" "context_id")
    local raw="false"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --raw)
                raw="true"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    canvas_http_get "/contexts/$context_id/workspace" "" "$raw"
}

#########################################
# Document management                   #
#########################################

# Add a note
function context_note_add() {
    local content=""
    local title=""
    local tags=""
    local file_path=""

    # Parse arguments: look for --path, --title, --tags, and positional content
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                title="$2"
                shift 2
                ;;
            --tags)
                tags="$2"
                shift 2
                ;;
            --path)
                file_path="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Unknown option: $1"
                return 1
                ;;
            *)
                # First non-option argument is content
                if [ -z "$content" ]; then
                    content="$1"
                else
                    content="$content $1"
                fi
                shift
                ;;
        esac
    done

    # After parsing, check for both content and file_path
    if [ -n "$content" ] && [ -n "$file_path" ]; then
        echo "Error: Cannot provide both note content and --path. Please use only one."
        return 1
    fi

    if [ -n "$file_path" ]; then
        if [ ! -f "$file_path" ]; then
            echo "Error: File not found: $file_path"
            return 1
        fi
        content=$(<"$file_path")
    fi

    if [ -z "$content" ]; then
        echo "Error: Missing note content. Provide content as an argument or use --path <file>."
        return 1
    fi

    local context_id=$(get_value "$CANVAS_SESSION" "context_id")

    # Build the feature array with note abstraction and tags
    local feature_array='["data/abstraction/note"'
    if [ -n "$tags" ]; then
        IFS=',' read -ra TAG_ARRAY <<< "$tags"
        for tag in "${TAG_ARRAY[@]}"; do
            feature_array="$feature_array, \"tag/$tag\""
        done
    fi
    feature_array="$feature_array]"

    # Use jq --arg for robust JSON construction
    local tmpjson
    tmpjson=$(mktemp)
    jq --arg content "$content" --arg title "$title" --argjson featureArray "$feature_array" '
        {featureArray: $featureArray, documents: {schema: "data/abstraction/note", data: {content: $content} } }
        | if $title != "" then .documents.data.title = $title else . end
    ' <<< '{}' > "$tmpjson"
    canvas_http_post "/contexts/$context_id/documents" "$tmpjson" | jq .
    rm -f "$tmpjson"
}

# List notes
function context_notes() {
    local context_id=$(get_value "$CANVAS_SESSION" "context_id")
    canvas_http_get "/contexts/$context_id/documents?featureArray=data/abstraction/note" | jq .
}

# List tabs
function context_tabs() {
    local context_id=$(get_value "$CANVAS_SESSION" "context_id")
    canvas_http_get "/contexts/$context_id/documents?featureArray=data/abstraction/tab" | jq .
}

# Add a tab
function context_tab_add() {
    local url="$1"
    shift

    if [ -z "$url" ]; then
        echo "Error: Missing tab URL"
        return 1
    fi

    local title=""
    local tags=()

    # Parse optional parameters
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                title="$2"
                shift 2
                ;;
            -t)
                tags+=("$2")
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done

    local context_id=$(get_value "$CANVAS_SESSION" "context_id")

    # Build the feature array with tab abstraction and tags
    local feature_array='["data/abstraction/tab"'
    for tag in "${tags[@]}"; do
        feature_array="$feature_array, \"tag/$tag\""
    done
    feature_array="$feature_array]"

    # Build the data object for the tab document
    local data_obj="{\"url\": \"$url\""
    if [ -n "$title" ]; then
        data_obj="$data_obj, \"title\": \"$title\""
    fi
    data_obj="$data_obj}"

    # Build the complete request data with the new schema under 'documents'
    local data="{\"featureArray\": $feature_array, \"documents\": {\"schema\": \"data/abstraction/tab\", \"data\": $data_obj}}"

    canvas_http_post "/contexts/$context_id/documents" "$data" | jq .
}

# Main context function
function context() {
    # Check for arguments
    if [[ $# -eq 0 ]]; then
        echo "Error: missing argument"
        context_usage
        return 1
    fi

    # Parse command and arguments
    local cmd="$1"
    shift

    # Main switch
    case "$cmd" in
        list)
            context_list "$@"
            ;;
        switch)
            context_switch "$@"
            ;;
        set)
            context_set "$@"
            ;;
        create)
            context_create "$@"
            ;;
        destroy)
            context_destroy "$@"
            ;;
        url)
            context_url "$@"
            ;;
        base-url)
            context_base_url "$@"
            ;;
        path)
            context_path "$@"
            ;;
        paths)
            context_paths "$@"
            ;;
        tree)
            context_tree "$@"
            ;;
        workspace)
            context_workspace "$@"
            ;;
        documents)
            canvas_http_get "/contexts/$context_id/documents" "" "$raw"
            ;;
        note)
            if [[ "$1" == "add" ]]; then
                shift
                context_note_add "$@"
            else
                echo "Unknown note subcommand: $1"
                context_usage
                return 1
            fi
            ;;
        notes)
            context_notes
            ;;
        tabs)
            context_tabs
            ;;
        tab)
            if [[ "$1" == "add" ]]; then
                shift
                context_tab_add "$@"
            else
                echo "Unknown tab subcommand: $1"
                context_usage
                return 1
            fi
            ;;
        help)
            context_usage
            ;;
        *)
            echo "Unknown context command: $cmd"
            context_usage
            return 1
            ;;
    esac
}

