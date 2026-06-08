# Parman Automated Notification POC

Node-RED proof of concept for safe local automation:

- meeting invitations
- birthday greetings
- notifications
- recipient groups
- meeting reminders
- schedules and run logs
- delivery history and retry support
- backup/restore
- safe-mode settings and SMTP readiness planning

All email is sent to local Mailpit. Real email is intentionally disabled.

## Current Status

This repo contains the dashboard files, templates, examples, and Node-RED deployment scripts.

Important: this is not yet a one-command fresh install package. A fresh PC can run it, but the Node-RED flows must be deployed by running the checkpoint scripts in order.

The future improvement would be a `docker-compose.yml` plus one `setup.ps1` script.

## Requirements

- Windows 10/11
- Docker Desktop
- Git
- PowerShell
- Internet access for the first Docker image download

## Fresh PC Setup

Clone the repo:

```powershell
git clone https://github.com/BehrangBina/Automated_Notification.git
cd Automated_Notification
```

Start Node-RED:

```powershell
docker run -d --name parman-node-red -p 1880:1880 -v parman_nodered_data:/data --restart unless-stopped nodered/node-red:latest
```

Start Mailpit:

```powershell
docker run -d --name parman-mailpit -p 8025:8025 -p 1025:1025 --restart unless-stopped axllent/mailpit:latest
```

Open:

- Node-RED: http://localhost:1880
- Mailpit: http://localhost:8025

## Deploy The POC Flows

Run these scripts from the repo folder in PowerShell.

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint4.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint5.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint6a.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint6b.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint6c.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint7.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint8.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint9a.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint9b.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint10a.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint10b.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint10c.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint11a.ps1
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint11b.ps1
```

Then open the dashboard:

```text
http://localhost:1880/app/?v=latest#overview
```

If the dashboard looks old, press `Ctrl + F5`.

## Demo Guide

The handoff/demo guide is here:

```text
docs/demo-guide.md
```

Suggested demo path:

1. Open Settings and show safe mode.
2. Show SMTP readiness planning and the “no password in UI” rule.
3. Create or select a recipient group.
4. Send a meeting invite.
5. In the preview modal, type `SEND TO MAILPIT`.
6. Open Mailpit and show the email.
7. Show birthdays, notifications, schedules, run logs, delivery history, and backup/restore.

## Safe Mode

The dashboard remains in safe POC mode:

- email goes to local Mailpit
- real email is disabled
- SMTP settings are planning metadata only
- SMTP passwords/API keys must not be stored in the dashboard
- send previews require the `SEND TO MAILPIT` phrase

## Dashboard Features

- Meetings: Persian/English content, Zoom details, timezone display, calendar attachment
- Birthdays: saved contacts, local timezone/send hour, safe test sends
- Notifications: branded Persian/English messages
- Recipient groups: reusable email lists
- Schedules: automatic birthday check controls
- Meeting reminders: one-time scheduled reminder emails
- Run logs: manual/automatic schedule checks
- Delivery history: sent/failed/queued/duplicates/retry
- Settings: safe mode, SMTP readiness planning, backup/restore

## Useful URLs

- Dashboard: http://localhost:1880/app/
- Node-RED editor: http://localhost:1880
- Mailpit: http://localhost:8025
- Delivery history: http://localhost:1880/delivery-history

## API Summary

Birthday contacts:

- `GET /api/birthdays/contacts`
- `POST /api/birthdays/contacts`
- `DELETE /api/birthdays/contacts/:id`
- `POST /api/birthdays/check`

Meetings:

- `POST /api/meetings/send`

Notifications:

- `POST /api/notifications/send`

Recipient groups:

- `GET /api/recipient-groups`
- `POST /api/recipient-groups`
- `DELETE /api/recipient-groups/:id`

Schedules:

- `GET /api/schedules`
- `POST /api/schedules/:id`

Meeting reminders:

- `GET /api/meeting-reminders`
- `POST /api/meeting-reminders`
- `DELETE /api/meeting-reminders/:id`
- `POST /api/meeting-reminders/check`

Schedule run logs:

- `GET /api/schedule-runs`
- `DELETE /api/schedule-runs`

Delivery history:

- `GET /api/deliveries`
- `POST /api/deliveries/:id/retry`

Settings:

- `GET /api/settings`
- `POST /api/settings`

Backups:

- `GET /api/backups/export`
- `POST /api/backups/restore`

## Troubleshooting

If containers already exist:

```powershell
docker restart parman-node-red
docker restart parman-mailpit
```

If ports are already in use:

- Node-RED uses port `1880`
- Mailpit web UI uses port `8025`
- Mailpit SMTP uses port `1025`

If the dashboard does not update:

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint8.ps1
```

Then open:

```text
http://localhost:1880/app/?v=latest#settings
```

and press `Ctrl + F5`.

## Known Packaging Gap

The repo is shareable, but not yet fully packaged for one-command setup.

Recommended next packaging work:

- add `docker-compose.yml`
- add `setup.ps1`
- make setup deploy all flows automatically
- verify from a fresh Docker volume
