# X1 beta

Thanks for trying this. It is an early build and you are among the first
people outside the company to run it.

## What X1 is

A private AI agent that installs on your own machine. You pick one outcome, it
runs on a schedule, and the results land in a folder you own. Your files,
memory and vault stay on your machine. Only the specific question a task needs
goes to the model you choose, and you can run entirely locally instead.

## Before you start

- **Docker Desktop**, or Docker Engine with the Compose plugin on Linux.
- **An OpenRouter key**, free to create at
  [openrouter.ai/settings/keys](https://openrouter.ai/settings/keys). X1
  defaults to a free model, so this should cost you nothing. If you would
  rather nothing leaves your machine at all, choose "On this laptop" during
  setup and use Ollama instead.
- **Ten minutes** if you already have Docker. Closer to twenty five if not.
- macOS and Linux are tested. Windows has a PowerShell installer that is
  **not** yet tested, so expect problems and please tell us about them.

## Install

macOS or Linux, in Terminal:

    curl -fsSL https://raw.githubusercontent.com/X-Scale-AI/x1/main/x1-install.sh | bash

Windows, in PowerShell:

    irm https://raw.githubusercontent.com/X-Scale-AI/x1/main/x1-install.ps1 | iex

Your browser opens the setup portal. Pick an outcome, paste your OpenRouter
key, and finish. X1 then produces your first result while you watch, which
takes a minute or two, and schedules it to run daily.

## What we would like to know

Five questions. Short answers are fine, and blunt answers are better than
polite ones.

1. **Did you get to a result without help?** If you got stuck, where exactly?
2. **Was the first result worth having?** Would you have wanted it tomorrow
   morning without asking?
3. **What did you expect it to do that it did not?**
4. **What would make you keep it installed a month from now?**
5. **What would you pay for, if anything?** Naming nothing is a useful answer.

Use the **Feedback** button in the portal header. It opens an email with the
version and configuration already filled in, which saves you describing your
setup. Or reply to the message that sent you here.

## Known rough edges

Telling you up front so you do not waste time reporting what we already know:

- The installer prints dots in the terminal while you complete setup in the
  browser. It looks stuck. It is not.
- Windows is untested.
- A scheduled outcome only runs while Docker is running. If your laptop
  sleeps, X1 catches up when it wakes rather than running while asleep.
- Some outcomes are stronger than others. The market brief and sourced
  research are the most developed.
- There is no account, no billing, and nothing to pay for in this build.

## Day to day

    docker compose down            # stop, keep everything
    docker compose up -d           # start again
    ./scripts/backup-data.sh       # verified private backup
    ./scripts/factory-reset.sh     # delete all data, with confirmation

Your data is in the Docker volume `xscaleai-paa-data` on your machine. Nothing
is uploaded anywhere, and there is no telemetry in this build. If you want to
be rid of X1 entirely, `factory-reset.sh` and then delete the folder.

## Your key

Your OpenRouter key is written to `.env` in the install folder with
owner-only permissions and never leaves your machine. We never see it. Set a
spend limit on it at
[openrouter.ai/settings/keys](https://openrouter.ai/settings/keys) if you want
a hard ceiling, which is a good habit with any agent.
