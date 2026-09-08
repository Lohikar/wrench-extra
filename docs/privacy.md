# Privacy & Data Use

Wrench collects limited information in order to work. If you do not interact with Wrench, it will not retain any information about you, including if other users run commands targeting your account (such as avatar fetch). Most information accessible to wrench is processed in memory and is not retained. The following information is currently retained indefinitely, though can be deleted on request:

- Command run logs, including your username (but not persistent ID), the timestamp you ran the command, the guild and channel the command was run in, and if the command succeeded or failed.
	- Arguments passed to commands are not stored or retained, with the following exceptions:
		- Words added to word lists with template commands are stored in order for the command to function, but can be removed by the user at any time.
		- Server names passed to the `!ss13*` family of commands that do not match a server are retained so missing servers can be added.
		- Place names passed to `!weather` are cached on disk to avoid geolocation lookups where possible. This cache does not contain metadata, such as user identifiers or timestamp.
- Command run statistics (command run counters) at a per-guild level.
	- Statistics for commands in PMs are all aggregated into a single "guild", so cannot be attributed to individual users, though command logs are still active.
	- Identifiers for custom commands defined via guild configuration are retained by counters.
- A parsed version of a guild's configuration is retained in order to increase reliability, such as if the configuration channel is accidentally renamed.
	- This does not include comments, raw message contents, authorship information, or timestamps.
	- This is replaced on disk every time the configuration successfully loads, with old versions not retained. Loading a blank configuration will delete the cached configuration permanently.
- Code passed to the `!dm` command is temporarily written to disk in order to invoke the compiler. These files are normally immediately deleted, though may be inadvertently retained in some cases.
	- A processed form of the command is written rather than raw message contents, exact contents visible via `!ddm`.
	- Messages that fail to parse are not written to disk.
	- `!ddm` does not involve the compiler, so is not written to disk.
- Server status retrieved with the `!ss13*` family of commands indirectly logs which server was polled via diagnostic connection logs (e.g., 'connected to hostname:port').
- On boot, the number of channels in each loaded guild that the bot is able to read is logged for diagnostics purposes, as well as how many messages were read to construct configuration.
- The last 50 messages in a specially marked configuration channel (usually `#wrench-config`) are read to parse as configuration.
	- Raw messages are parsed in memory and not retained.
	- TOML comments in configuration are stripped during parse.
	- If configuration failed to load, additional information (such as syntax errors, which may contain partial raw config channel contents) is logged to assist with debugging configuration with the guild owner. These messages are identical to the ones shown to the guild owner. Raw messages are not logged.
	- If messages from users without authorization to configure the bot are encountered during configuration parse, the authors' usernames are written in logs to assist with debugging configuration with the guild owner. Message contents are not read, logged, or otherwise retained.

## Internal Logging

Command run logs take this form:

```
[2026-09-08 21:27:45.480 INFO wrench::dispatcher] USERNAME ran COMMAND (SCOPE) in ['GUILD' (GUILD ID) => CHANNEL GROUP/#CHANNEL]
```

Commands that contact an external server (such as a SS13 game server) may take the form of:

```
[2026-09-08 21:27:45.480 INFO wrench::dispatcher] USERNAME ran COMMAND (SCOPE) in ['GUILD' (GUILD ID) => CHANNEL GROUP/#CHANNEL]
[2026-09-08 15:30:24.993 INFO wrench::util::byond] Connection to DOMAIN:PORT (IP_ADDRESS:PORT) took 44ms after 1 attempt(s).
```

With `USERNAME` being a Discord username (potentially with discriminator), `COMMAND` being the identifier of the command that was executed (excluding arguments)
, `SCOPE` one of 'Global' or 'Guild' depending on where the command is defined, `GUILD` being the Discord-level display name for the guild, `GUILD ID` being the persistent snowflake ID of the guild, `CHANNEL GROUP` being the category the channel is in (if any), and `CHANNEL` being the display name of the channel.

## Hosting

All components of Wrench are self-hosted, currently physically located in Canada. Retained data is not shared with or accessible to third parties.

## Deletion Requests

To request deletion of data (such as command logs related to an account you own, cached config data for a guild you own, or template wordlists for a guild you own), send an email to `wrench AT lohikar DOT io`.
