# X1 by XScaleAI

Your secure personal AI agent. It installs on your own machine, runs one
outcome on a schedule, and keeps your context local.

## Install

macOS or Linux, in Terminal:

    curl -fsSL https://raw.githubusercontent.com/X-Scale-AI/x1/main/x1-install.sh | bash

Windows, in PowerShell:

    irm https://raw.githubusercontent.com/X-Scale-AI/x1/main/x1-install.ps1 | iex

Requires Docker Desktop, or Docker Engine with the Compose plugin on Linux.
The agent runtime and portal are pulled as pinned container images; nothing
else is downloaded.

## Day to day

    docker compose down            # stop, keep all data
    ./scripts/backup-data.sh       # verified private backup
    ./scripts/restore-data.sh f    # restore a backup
    ./scripts/factory-reset.sh     # delete the data volume, with confirmation

Your data lives in the Docker volume `xscaleai-paa-data` on this machine.

## License

X1 is proprietary software (see LICENSE.txt). The installer scripts in this
repository may be read and audited freely; no license is granted to
redistribute or reuse the X1 product itself.
