#!/bin/bash

SHELL_TYPE=${PLEASE_CONFIG_SHELL_TYPE:-zsh}

OS_VERSION=$(uname -sr)

SILENT=false
VERBOSE=false

OPENAI_REQUEST_MODEL="gpt-4o" # In testing, gpt-4o gives more accurate results than gpt-3.5-turbo
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

if [ -z "$PLEASE_CONFIG_OPENAI_API_KEY" ]; then
	print "No value found for env var 'PLEASE_CONFIG_OPENAI_API_KEY'. To use 'please', this env var must be set to a valid OpenAI API key."
	exit 1
fi

raw_request="$@"
verbose_print "RAW USER REQUEST: $raw_request"

# Prepare messages for sending
# TODO: Consider (must include asking for JSON format in the request): response_format={ "type": "json_object" }
escaped_system_message=$(jq -Rn --arg text "$OPENAI_REQUEST_COMMAND_SYSTEM_MESSAGE" '$text')
escaped_request_message=$(jq -Rn --arg text "$raw_request" '$text')
json_payload=$(cat <<EOF
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
verbose_print "API REQUEST PAYLOAD:\n$json_payload"

print "Thinking..."
response=$( \
	curl https://api.openai.com/v1/chat/completions \
		-sS \
		-w "%{http_code}" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $PLEASE_CONFIG_OPENAI_API_KEY" \
		-d "$json_payload" \
)
verbose_print "RAW RESPONSE:\n$response"
http_status="${response: -3}"
response_content=${response%???}
verbose_print "API REQUEST STATUS: $http_status"
verbose_print "API RESPONSE CONTENT:\n$response_content"

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
echo $command_text
