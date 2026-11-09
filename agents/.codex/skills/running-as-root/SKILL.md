---
name: running-as-root
description: Use when a command you are about to run needs root, or fails because it lacks root (permission denied, sudo password prompt).
---

# Running as root

- Use `pkexec` only when you, the agent, are executing a command through a terminal/tool and that command requires root. This lets the user enter their password in KDE's authentication dialog instead of an inaccessible or timing-out `sudo` prompt.
- This is an agent execution rule, not a requirement for the code you write. Do not add `pkexec` or a polkit dependency to scripts, installers, application code, CI, tests, documentation, or commands for users to copy and run because of this rule. Follow the project's normal privilege handling, such as `sudo`, unless the user explicitly requests otherwise.
- If a script must run as root, put `pkexec` in your tool invocation, for example `pkexec bash ./root-task.sh`. Do not embed it in the script or change the script's privilege handling just because you will execute it.
- If you cannot authenticate through `pkexec`, ask the user to run the required command in their terminal using the project's normal method, such as `sudo`.
