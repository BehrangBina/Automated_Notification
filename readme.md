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
