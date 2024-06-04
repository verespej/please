# please

Work from the command line using natural language rather than searching the internet for obscure commands.

For example, say `please go to my home directory` instead of `cd ~`.

Documentation in non-English languages:
- [Español](./README.es.md)

# Summary

`please` allows using natural language on the command line.

To minimize dependencies and maintenance requirements:
1. It's implemented as a shell script
2. It depends only on common command line tools

It has one major _external_ dependency, which is the [OpenAI API](https://platform.openai.com/docs/overview). This is how it goes from natural language to something we can execute on the command line.

# Install

## Preparation

`please` requires a unix-like command line. For example, `bash`, `zsh`, etc.

To start, make sure you have the following tools installed and available via the command line:
- `bash`: You most likely already have `bash` installed if you're using a Unix-like system. If you're using Windows, [here are some helpful instructions](https://www.educative.io/answers/how-to-install-git-bash-in-windows)
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

Install the main script (requires `sudo` since `/usr/local/bin` is generally owned by the root user):
```
sudo mkdir -p /usr/local/bin
sudo curl https://raw.githubusercontent.com/verespej/please/main/please.sh -o /usr/local/bin/please
sudo chmod +x /usr/local/bin/please
```

Add the following to your shell config (e.g. `~/.zshrc`, `~/.bashrc`, etc.)
```
# Ensure user bin location is in PATH
! (echo ":$PATH:" | grep -q ":/usr/local/bin:") && export PATH=$PATH:/usr/local/bin
export PLEASE_CONFIG_SHELL_TYPE="<zsh, bash, etc.>"
export PLEASE_CONFIG_OPENAI_API_KEY="<your OpenAI key>"
```

Reload the shell config:
```
source <your shell config file>
```

## Setting up Automatic Execution of Commands

This is optional. It executes the command resulting from the request automatically.

If you use this, be careful. Even though it has lightweight protection against destructive commands, there're many it doesn't prevent.

Add the following to your shell config (e.g. `~/.zshrc`, `~/.bashrc`, etc.)
```
please() {
  command_text=$(/usr/local/bin/please "$@") && {
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
source <your shell config file>
```

# Usage

Here're a couple example requests and outputs. Note that output may differ on your computer.

Change directory
```
> pwd
/Users/devuser
> please go to my Downloads folder
2024-06-03 13:14:34: Thinking...
2024-06-03 13:14:35: Solution: cd ~/Downloads
> pwd
/Users/devuser/Downloads
```

Find files
```
> please find all pdf files with "test" in the name recursively
2024-06-03 13:20:56: Thinking...
2024-06-03 13:20:57: Solution: find . -type f -iname '*test*.pdf'
./testdir1/testfile2.pdf
./testfile1.pdf
```

Diff arbitrary files using git
```
> please use git to diff non-versioned files README.md and README.es.md
2024-06-03 16:32:52: Thinking...
2024-06-03 16:32:53: Solution: git diff --no-index README.md README.es.md
...
```

Resize an image (😂 look how it changed it's mind about how to approach the task)
```
> please transform profile-photo-copy.png to 150x150
2024-06-03 15:12:46: Thinking...
2024-06-03 15:12:48: Solution: convert profile-photo-copy.png -resize 150x150 profile-photo-copy-150x150.png
(eval):1: command not found: convert
ERROR: Request failed

> please install the convert tool
2024-06-03 15:37:01: Thinking...
2024-06-03 15:37:02: Solution: brew install imagemagick
...

> please transform profile-photo-copy.png to 150x150
2024-06-03 15:39:19: Thinking...
2024-06-03 15:39:20: Solution: sips -z 150 150 profile-photo-copy.png
/Users/hakon/Downloads/profile-photo-copy.png
  /Users/hakon/Downloads/profile-photo-copy.png

> please transform profile-photo-copy.png to 150x150
2024-06-03 15:39:19: Thinking...
2024-06-03 15:39:20: Solution: sips -z 150 150 profile-photo-copy.png
/Users/hakon/Downloads/profile-photo-copy.png
  /Users/hakon/Downloads/profile-photo-copy.png

> please transform profile-photo-copy.png to 100x100 using convert
2024-06-03 15:41:27: Thinking...
2024-06-03 15:41:29: Solution: convert profile-photo-copy.png -resize 100x100 profile-photo-copy-100x100.png
WARNING: The convert command is deprecated in IMv7, use "magick"

> please transform profile-photo-copy.png to 100x100 using magick
2024-06-03 15:41:48: Thinking...
2024-06-03 15:41:50: Solution: magick profile-photo-copy.png -resize 100x100 profile-photo-copy-100x100.png
```

What is this program (🤷 room for improvement)
```
> please tell me about yourself
2024-06-03 15:44:37: Thinking...
2024-06-03 15:44:38: Solution: echo "I am a zsh shell command expert."
COMMAND: echo "I am a zsh shell command expert."
WARNING: The command has NOT been executed. This is because 'zsh' is a potentially destructive or otherwise dangerous operation. If you wish to execute the command, you must do so manually. DON'T execute it unless you fully understand what it does.
```

## Known Limitations

Standard shell rules apply. In particular, certain characters have special meaning in the shell. Requests that contain such characters may be passed to the program as expected.

For example, `>` is used for output redirection. So, the following request won't work:
```
please determine if 3 > 2
```

Instead, it needs to be written as:
```
please determine if 3 \> 2
```

# Design Questions

Q: Why use a shell script instead of something like python or node?
A: To try to minimize the potential complexity of dependencies

Q: Why use a shell function for execution rather than doing `eval` in the bash script?
A: For the following reasons:
- To produce commands that work if run manually in the user's console (and not just in `bash`)
- Since the script runs as a subshell, it can't perform actions that might be desired in the parent shell
    - Example: Changing directory with `cd`
    - Example: Referencing the home directory with `~`
- To create separation between retrieving the command and executing it


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

See the [LICENSE](./LICENSE.md) file for license rights and limitations (MIT).
