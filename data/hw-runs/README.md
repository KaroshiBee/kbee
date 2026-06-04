# Hardware Run Logs

This folder stores bench-run evidence for `kbee-04` hardware testing.

Completed logs record live captures and checker results. Template or
pipeline-only runs (e.g. preflight against reference CSVs) are labelled as such
in the file header.

## Naming

Use one markdown log per run day:

- `YYYY-MM-DD-kbee-04-hw-log.md`

## Required fields per capture

For each capture/check, record:

- file path
- probe map used
- waveform files used
- checker command used
- pass/fail and key metrics
- git SHA

## Starter template

Copy this block into a new run log file:

```md
# kbee-04 hardware run log

- Date:
- Operator:
- Board:
- Host:
- AD2 version:
- Git SHA:

## Capture 1
- Capture file:
- Probe map:
- Waveforms:
- Command:
- Result:
- Metrics:

## Capture 2
- Capture file:
- Probe map:
- Waveforms:
- Command:
- Result:
- Metrics:
```
