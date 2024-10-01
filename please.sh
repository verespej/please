#!/bin/bash

SHELL_TYPE=${PLEASE_CONFIG_SHELL_TYPE:-zsh}

OS_VERSION=$(uname -sr)

SILENT=false
VERBOSE=false

REQUEST_LOG_DIR="$HOME/.local/state/please/logs" # Comment out line to disable request logging

CACHE_DIR="$HOME/.local/share/please" # Comment out line to disable caching
CACHE_FILE="${CACHE_DIR:+$CACHE_DIR/cache}" # Only set if CACHE_DIR is set
CACHE_ENTRY_SEPARATOR=' :::: '

OPENAI_REQUEST_MODEL="gpt-4o" # Using this model without the version suffix will use the latest default version
OPENAI_REQUEST_MAX_TOKENS=1024
OPENAI_REQUEST_TEMPERATURE=0.7

OPENAI_REQUEST_COMMAND_SYSTEM_MESSAGE="\
You are a $SHELL_TYPE shell command expert. \
When I send you a message, you reply with only the text of a functioning $SHELL_TYPE shell command for a shell running on '$OS_VERSION'. \
You do not provide any additional information and do not include any mark-up in the text. \
You only provide the text of a command ready to run in the shell and nothing else. \
Your commands are concise, fitting in a single line, whenever possible. \
"
OPENAI_REQUEST_EXPLAIN_SYSTEM_MESSAGE="\
You are a $SHELL_TYPE shell command analyst. \
When I send you a message, you interpret it as a shell command and provide a breakdown of it. \
The breakdown should start with a one-line summary of what the command does, then provide the breakdown in a bulleted or numbered list. \
"

print() {
	# We echo to stderr so we can print messages without affecting output
	# captured by the caller
	[ "$SILENT" = false ] && echo "$(date +"%Y-%m-%d %H:%M:%S"): $@" >&2
}

verbose_print() {
	[ "$VERBOSE" = true ] && print $@
}

log_request_response() {
	local request_json="$1"
	local response_json="$2"

	[[ -z "$REQUEST_LOG_DIR" ]] && return 0

	local data="{ \"timestamp\": \"$(date +"%Y-%m-%d %H:%M:%S")\", \"request\": $request_json, \"response\": $response_json }"
	local formatted_data=$(echo "$data" | jq .)
	mkdir -p "$REQUEST_LOG_DIR"
	echo "$formatted_data" >> "$REQUEST_LOG_DIR/api-requests.log"
}

save_to_cache() {
	local request_text="$1"
	local response_text="$2"

	[[ -z "$CACHE_DIR" ]] && return 0

	mkdir -p "$CACHE_DIR"
	echo "$request_text$CACHE_ENTRY_SEPARATOR$response_text" >> "$CACHE_FILE"
}

get_from_cache() {
	local request_text="$1"

	[ ! -f "$CACHE_FILE" ] && return 0

	# If there's an exact (non-regex) match for the request + separator...
	if grep -Fq "$request_text$CACHE_ENTRY_SEPARATOR" "$CACHE_FILE"; then
		# Return the value part of the last match
		grep -F "$request_text$CACHE_ENTRY_SEPARATOR" "$CACHE_FILE" | awk -F "$CACHE_ENTRY_SEPARATOR" '{last=$2} END {if (last) print last}'
	fi
}

if [ -z "$PLEASE_CONFIG_OPENAI_API_KEY" ]; then
	print "No value found for env var 'PLEASE_CONFIG_OPENAI_API_KEY'. To use 'please', this env var must be set to a valid OpenAI API key."
	exit 1
fi

# Due to shell interpretation, we lose inputs like quotes. Ideally, we'd
# be able to get the exact text written to invoke the script. Unfortunately,
# it seems this isn't possible. Instead, we just take a practical approach
# of trying recover quotes by adding them around any params with spaces.
# Note: I don't like that this (1) risks making some requests impossible
# since they shouldn't have quotes and (2) may add quotes where the user
# didn't have them. However, it does keep the experience a little more
# magical. We should re-evaluate later and remove this or add additional
# documentation about it.
reconstructed_input=''
for arg in "$@"; do
	[[ "$arg" =~ \  ]] && arg="\"$arg\""
	reconstructed_input="$reconstructed_input $arg"
done
reconstructed_input="${reconstructed_input# }"

raw_request="$reconstructed_input"
print "Request: $raw_request"

# Try getting a cached value before making an API call
cached_command_text=$(get_from_cache "$raw_request")
if [[ -n "$cached_command_text" ]]; then
	print "Solution (from cache): $cached_command_text"
	echo $cached_command_text
	exit 0
fi

# Prepare messages for sending
escaped_system_message=$(jq -Rn --arg text "$OPENAI_REQUEST_COMMAND_SYSTEM_MESSAGE" '$text')
escaped_request_message=$(jq -Rn --arg text "$raw_request" '$text')
request_payload=$(cat <<EOF
{
	"model": "$OPENAI_REQUEST_MODEL",
	"messages": [
		{"role": "system", "content": $escaped_system_message},
		{"role": "user", "content": $escaped_request_message}
	],
	"max_tokens": $OPENAI_REQUEST_MAX_TOKENS,
	"temperature": $OPENAI_REQUEST_TEMPERATURE
}
EOF
)
verbose_print "API REQUEST PAYLOAD:\n$request_payload"

print "Thinking..."
response=$( \
	curl https://api.openai.com/v1/chat/completions \
		-sS \
		-w "%{http_code}" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $PLEASE_CONFIG_OPENAI_API_KEY" \
		-d "$request_payload" \
)
verbose_print "RAW RESPONSE:\n$response"

http_status="${response: -3}"
response_content=${response%???}
verbose_print "API REQUEST STATUS: $http_status"
verbose_print "API RESPONSE CONTENT:\n$response_content"
log_request_response "$request_payload" "$response_content"

# Check for http error
if [[ "$http_status" != 2* ]]; then
	if [[ -z "$response_content" ]]; then
		print "API request failed: ($http_status) <No content>"
	else
		print "API request failed: ($http_status) $response_content"
	fi
	exit 1
fi

# Check for API error
if echo $response_content | jq -e '.error' >/dev/null; then
	error_type=$(echo $response_content | jq -r '.error.type')
	error_text=$(echo $response_content | jq -r '.error.message')
	print "API request failed: ($error_type) $error_text"
	exit 1
fi

command_text=$(echo $response_content | jq -r '.choices[].message.content')
print "Solution: $command_text"
save_to_cache "$raw_request" "$command_text"
echo $command_text
