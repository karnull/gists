# SysHacks

A collection of independent shell scripts (gists) designed to power up the
terminal experience. Each script solves one specific task with no
cross-dependencies — drop any of them onto `$PATH` and use it on its own.

## Scripts

### `battery_cap.sh`
Limit a laptop battery from overcharging. Define a maximum charge limit inside
the script; if the model is supported, it installs a systemd service that caps
charging at the specified threshold.

### `resistor.c`
Decode resistor colour bands. Pass band colours (e.g. `blue red green gold`) to
get the resistance value, or run with no arguments for a reference table.

