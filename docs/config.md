---
title: Configuration
---

# Configuration

To start configuring wrench, you need to create a channel named `wrench-config`. The channel should:

- Be readable by wrench (_Read Messages_ permission)
- Be writable by wrench (_Send Messages_ permission)
- Only allow users with MANAGE_GUILD / Manage Server to send messages.
- Only contain configuration messages (don't run commands or talk in it)

When Wrench reads the config, it will join the last 50 messages in the channel together (ignoring messages from users without the _Manage Server_ permission), strip code block markers (\`\`\`), and parse it as [TOML](https://toml.io/en/v1.0.0). It's a good practice to delete wrench errors in the channel after you've fixed them as they count towards this 50 message limit, though they won't be parsed as configs.

*All* messages in this channel count towards the 50 message limit regardless of if they get parsed for config -- __any user that can send messages in the config channel can cause the config to not load, even if they don't have permission to actually write config!__

Syntax coloring is supported in configs and will not interfere with parsing -- put `toml` after the triple-grave but before the newline.

## Config Sections

There are 5 sections in Wrench's config: general, commands, alias, and modules. All sections except alias can only appear once in the configuration channel, so must be configured in one message each at most. Except where otherwise noted, options or sections can be omitted to use defaults.

### General

General bot or command configuration.

```toml
[general]
prefix = "!"
default_server = "some server"    # not specified by default
weather_for = "some location"     # not specified by default
silent_unknown_cmd = false
```

| Key                  | Kind    | Default     |
|----------------------|---------|-------------|
| `prefix`             | String  | `!`         |
| `default_server`     | String  | Unspecified |
| `weather_for`        | String  | Unspecified |
| `silent_unknown_cmd` | Boolean | false       |

#### Prefix

This directive sets the prefix wrench uses for commands. Can be set to any Unicode string, as long as it does not contain discord formatting symbols, or the @ symbol. Wrench will always respond to the `wrench.` prefix regardless of this setting.

#### Default Server

This directive sets the default SS13 server used in the SS13 server status commands. Should be one of the values listed in `!ss13servers`.

#### Weather For

This directive sets the default location for the `!weather` command. Any string allowed, though you probably want it to be an actual location.

#### Silent Unknown Cmd

This directive enables or disables the command-not-found message printed whenever a command that does not exist (or is not enabled) is run. Set to `true` to disable the CNF message.

---

### Commands

Enabling and disabling of commands within a module. It's recommended to prefer enabling/disabling via the `module` section instead of this, if possible. `module` and `commands` can be used simultaneously.

```toml
[commands]
blacklist = []
whitelist = []
strict_mode = false
```

| Key           | Kind           | Default |
|---------------|----------------|---------|
| `blacklist`   | List of String | empty   |
| `whitelist`   | List of String | empty   |
| `strict_mode` | Boolean        | false   |

#### Blacklist

A list of commands to disable. This should only be used to disable commands within a module, and System commands cannot be blacklisted. Ignored when `strict_mode` is `true`.

#### Whitelist

A list of commands to enable. When `strict_mode` is off, this allows enabling commands that are blacklisted by default. When `strict_mode` is on, this specifies the commands that are allowed to be used.

#### Strict Mode

Enables strict command whitelisting. When this is on, only commands in the `whitelist` field are allowed to be used. System commands always function, regardless of this option.

It is recommended to use the `module` section's `only` field instead of this.

---

### Modules

Enables or disables modules (groups of commands). Available modules can be viewed using `!modules` - strikethrough indicates disabled. System modules (`system`, `help`) cannot be disabled.

```toml
[modules]
enable = []
disable = []
```

OR

```toml
[modules]
only = []
```

| Key       | Kind           | Default | Conflicts With      |
|-----------|----------------|---------|---------------------|
| `enable`  | List of String | empty   | `only`              |
| `disable` | List of String | empty   | `only`              |
| `only`    | List of String | empty   | `enable`, `disable` |

#### Enable

Enables modules that are disabled by default. Cannot be used with `only`.

#### Disable

Disables modules that are enabled by default. Cannot be used with `only`.

#### Only

Enables only these modules, disabling all others. Cannot be used with `enable` or `disable`.

---

### Aliases

Allows specifying persistent aliases to existing commands, optionally with arguments. This section can be repeated, and it can appear in multiple config messages.

```toml
[[alias]]
name = ""	# The name of the alias -- what users enter to run it.
invokes = ""	# Which command this alias runs -- this must just be a command name, no args can go here.
args = ""	# Any args to append to the command that's actually run. If the user has specified args, they'll be placed after this with a separating space.
no_append = false	# If true, user args will be ignored instead of appended.
```

| Key       | Kind   | Required |
|-----------|--------|----------|
| `name`    | String | Yes      |
| `invokes` | String | Yes      |
| `args`    | String | No       |

---

### Templates

A repeatable section that allows definition of adlibs-like text templates. Like aliases, this section can appear in multiple config messages.

Word lists are implicitly defined by usage in the template string, and are not shared between templates or guilds. A word list can be used multiple times in a template, but a new word will be picked randomly (possibly the same one) each time.

All users can add or remove words to word lists. Run `!help <yourtemplate>` for information on usage of the command, such as manipulating word lists.

```toml
[[templates]]
key = "mytemplate"	# The name of the template -- what users enter to run it.
desc = "My text template."	# if specified, show this help text in the cmds listing
template = "This is a [adjective] example showing how the [adjective] [noun] system [descriptor]."
nsfw = false	# if true, template only usable in NSFW channels
```

| Key        | Kind    | Required |
|------------|---------|----------|
| `key`      | String  | Yes      |
| `template` | String  | Yes      |
| `nsfw`     | Boolean | No       |
| `desc`     | String  | No       |

#### Text Macros

The literal `#a/an#` can be inserted into a template to automatically insert a or an based on the value of the next word list in the template.

### Template Aliases

These are a special form of alias specific to templates -- they can apply a text filter to the template. Template aliases *do not* inherit NSFW status from their parent template.

```toml
[[template_alias]]
name = "mytemplatealias"	# The name of the template -- what users enter to run it.
invokes = "mytemplate"	# The template that this alias invokes.
mode = "NoFilter"	# Which filter mode should be used on the template.
```

| Key       | Kind                       | Required |
|-----------|----------------------------|----------|
| `name`    | String                     | Yes      |
| `invokes` | String                     | Yes      |
| `mode`    | Enum ("NoFilter", "Hewwo") | No       |
