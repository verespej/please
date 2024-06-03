# please

Work from the command line using natural language rather than memorizing or searching the internet for obscure commands.

For example, say `please go to my home directory` instead of `cd ~`.

Documentation in non-English languages:
- [Español](./README.es.md)

# Summary

`please` allows interacting with the command line using natural language.

It attempts to minimize the dependencies and maintenance required by:
1. Being implemented as a shell script
2. Depending only on common command line tools

However, it has one major _external_ dependency, which is the [OpenAI API](https://platform.openai.com/docs/overview). This is how it goes from natural language to something usable via the command line.

# Install

## Preparation

`please` requires a unix-like command line. For example, `bash`, `zsh`, etc.

To start, make sure you have the following tools installed and available via the command line:
- `bash`: You most likely already have `bash` installed if you're using a Unix-like system. If on Windows, [here are some helpful instructions](https://www.educative.io/answers/how-to-install-git-bash-in-windows)
- `curl`: If you don't already have `curl` installed, [here are some helpful instructions](https://everything.curl.dev/install/index.html)
- `jq`: If you don't already have `jq` installed, [here are some helpful instructions](https://jqlang.github.io/jq/download/)

## Getting an OpenAI API Key

`please` requires having an OpenAI account, a positive credit balance, and an API key.

- To create an OpenAI account, visit [the signup page](https://platform.openai.com/signup)
- To add credit, visit [the billing page](https://platform.openai.com/settings/organization/billing/overview)
- To generate an API key, visit OpenAI's [API platform projects article](https://help.openai.com/en/articles/9186755-managing-your-work-in-the-api-platform-with-projects#h_79e86017fd) and:
    - Create a project by following the guidance in the "How do I create a project?" section
    - Create a service account by following the guidance in the "What is a service account, and how does it differ from a regular user account?" section
    - Create an API key by following the guidance int he "How do I manage API keys within my organization's projects?" section
    - It's also strongly recommended to read and follow the [best practices for API key safety article](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety)

## Setting up `please`

Install the main script:
```
curl https://raw.githubusercontent.com/verespej/please/main/please.sh -o /usr/local/bin/please
chmod +x /usr/local/bin/please
```

Add the following to your shell config (e.g. `.zshrc`, `.bashrc`, etc.)
```
# Ensure script location is in PATH
! (echo ":$PATH:" | grep -q ":/usr/local/bin:") && export PATH=$PATH:/usr/local/bin
export PLEASE_CONFIG_SHELL_TYPE="<zsh, bash, etc.>"
export PLEASE_CONFIG_OPENAI_API_KEY="<your OpenAI key>"
# Note: This function can have the same name as the main script because the shell expands functions prior to searching PATH
please() {
  command_text=$(~/dev/please/please.sh "$@") && {
    restricted_commands=(">" "bash" "chmod" "chown" "cp" "curl" "dd" "fdisk" "mkfs" "mv" "parted" "rm" "wget" "zsh")
    for restricted_command in "${restricted_commands[@]}"; do
      if [[ "$command_text" == *"$restricted_command"* ]]; then
        echo "COMMAND: $command_text"
        echo "WARNING: The command has NOT been executed. This is because '$restricted_command' is a potentially destructive or otherwise dangerous operation. If you wish to execute the command, you must do so manually. DON'T execute it unless you fully understand what it does."
        return 1
      fi
    done
    eval $command_text
  } || {
    echo "ERROR: Request failed"
  }
}
```

Reload the shell config:
```
source $SHELL_FILE
```

# Usage

Here're a couple example requests and outputs. Note that output may differ on your computer.

Change directory
```
```

List
```
```

Install a package
```
```

Explain
```
```

# Design Questions

Q: Why use a shell script instead of something like python or node?
A:
- A goal is to minimize the potential complexity of dependencies

Q: Why use a shell function for execution rather than doing `eval` in the bash script?
A:
- A goal is to produce commands that work if run manually in the user's console
- Since the script runs as a subshell, it can't perform actions that might be desired in the parent shell
    - Example: Changing directory with `cd`
    - Example: Referencing the home directory with `~`


# Example OpenAI API Call Responses

## Example Success Response
```
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "created": 1717170785,
  "model": "gpt-4o-2024-05-13",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "echo \"hello\""
      },
      "logprobs": null,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 98,
    "completion_tokens": 4,
    "total_tokens": 102
  },
  "system_fingerprint": "fp_..."
}
```

## Example Error Response
```
{
  "error": {
    "message": "We could not parse the JSON body of your request...",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}
```

# License

See the [LICENSE](LICENSE.md) file for license rights and limitations (MIT).
