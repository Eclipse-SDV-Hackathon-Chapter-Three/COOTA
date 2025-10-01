# Safety State Alternator

This simple Bash script alternates the content of a `.safety_state` file between `SAFE` and `DRIVING` at a fixed interval.

## Features
- Alternates between `SAFE` and `DRIVING`.
- Configurable interval in seconds.
- Runs indefinitely until stopped.

## Requirements
- Bash shell
- Unix-like operating system (Linux, macOS)

## Usage
1. Save the script as `update_safety.sh`.
2. Make it executable:

```bash
chmod +x update_safety.sh
```

3. Run the script:

```bash
./update_safety.sh
```

4. The `.safety_state` file will update every `INTERVAL` seconds.