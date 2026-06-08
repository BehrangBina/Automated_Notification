# How to

## Install docker desktop

## Install Node-Red

`docker run -d --name parman-node-red -p 1880:1880 -v parman_nodered_data:/data --restart unless-stopped nodered/node-red:latest`

Node-Red will be on: [http://localhost:1880](http://localhost:1880)

## Install mail pit

`docker run -d --name parman-mailpit -p 8025:8025 -p 1025:1025 --restart unless-stopped axllent/mailpit:latest`

Mailpit: will be [http://localhost:8025](http://localhost:8025.)

## send our first test email from Node-RED into Mailpit

## Local dashboard

The POC dashboard is served by Node-RED:

[http://localhost:1880/app/](http://localhost:1880/app/)

It provides forms for meetings, birthday contacts, notifications, and delivery history.

Birthday contacts can be created, edited, selected for a safe test, and deleted with confirmation.

Recipient groups can be created once and reused in meeting, birthday, and notification forms.

Meeting, birthday test, and notification sends require a preview confirmation before the API call is made.

Schedules can be viewed and enabled/disabled from the dashboard. Checkpoint 10A controls the automatic birthday check.

Meeting reminders can be scheduled from the dashboard and are sent once when due.

Schedule run logs show when birthday checks and meeting-reminder checks ran, whether they were manual or automatic, and a compact summary of what happened.

Safety settings show the current safe-mode configuration and production-readiness checklist. Checkpoint 11A does not enable live email.

Backups can be exported and restored as JSON. Restore keeps live email disabled and routes email to Mailpit.

Send guardrails require preview approval and the `SEND TO MAILPIT` phrase before test emails are accepted from the dashboard.

SMTP readiness fields are planning metadata only. Do not store SMTP passwords or API keys in the dashboard; future secrets should come from Docker or Node-RED environment variables.

The demo and handoff guide is in `docs/demo-guide.md`.

To redeploy the dashboard after rebuilding the Node-RED container:

`powershell -ExecutionPolicy Bypass -File .\deploy-checkpoint8.ps1`

The dashboard remains in safe POC mode: email is delivered to local Mailpit, not real recipients.

Checkpoint 9A delete API:

`DELETE /api/birthdays/contacts/:id`

Checkpoint 9B recipient-group APIs:

- `GET /api/recipient-groups`
- `POST /api/recipient-groups`
- `DELETE /api/recipient-groups/:id`

Checkpoint 10A schedule APIs:

- `GET /api/schedules`
- `POST /api/schedules/:id`

Checkpoint 10B meeting-reminder APIs:

- `GET /api/meeting-reminders`
- `POST /api/meeting-reminders`
- `DELETE /api/meeting-reminders/:id`
- `POST /api/meeting-reminders/check`

Checkpoint 10C schedule-run log APIs:

- `GET /api/schedule-runs`
- `DELETE /api/schedule-runs`

Checkpoint 11A safety settings APIs:

- `GET /api/settings`
- `POST /api/settings`

Checkpoint 11B backup APIs:

- `GET /api/backups/export`
- `POST /api/backups/restore`
