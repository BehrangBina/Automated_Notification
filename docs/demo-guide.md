# Parman Automation POC Demo Guide

## Purpose

This POC shows how Node-RED can help Parman send safe test emails for meetings, birthday greetings, notifications, reminders, and operational follow-up.

All email is still routed to local Mailpit. Real email is intentionally disabled.

## Start Locally

1. Start Docker Desktop.
2. Start or verify the containers:
   - Node-RED: `http://localhost:1880`
   - Dashboard: `http://localhost:1880/app/`
   - Mailpit: `http://localhost:8025`
3. If the dashboard looks old, open `http://localhost:1880/app/?v=demo#settings` and press `Ctrl + F5`.

## Demo Script

1. Open the dashboard.
2. Show the left navigation:
   - Meetings
   - Birthdays
   - Notifications
   - Recipient groups
   - Schedules
   - Delivery history
   - Settings
3. Open Settings and show:
   - Safe mode is active
   - Live email is disabled
   - SMTP readiness is planning only
   - No SMTP password field exists
   - Backup and restore are available
4. Open Recipient groups and show that reusable recipient lists can be saved.
5. Open Meetings and show:
   - timezone-aware meeting form
   - Zoom details
   - recipient group support
   - preview before send
   - `SEND TO MAILPIT` approval phrase
6. Open Mailpit and show the generated email.
7. Open Birthdays and show:
   - saved birthday contacts
   - local timezone/send hour
   - safe birthday test
8. Open Notifications and show:
   - Persian/English message option
   - branded notification layout
   - preview and approval phrase
9. Open Schedules and show:
   - birthday schedule control
   - meeting reminders
   - schedule run log
10. Open Delivery history and show:
   - sent/failed status
   - duplicate prevention
   - retry support

## QA Checklist

- Dashboard loads from `http://localhost:1880/app/`.
- Mailpit loads from `http://localhost:8025`.
- Test sends appear in Mailpit only.
- Send preview blocks confirmation until `SEND TO MAILPIT` is typed.
- Settings still says live email is disabled.
- Backup JSON can be exported.
- Restore keeps live email disabled.
- Schedule run log updates after manual checks.

## Production Notes

- Do not store SMTP passwords or API keys in the dashboard.
- Future SMTP secrets should come from Docker or Node-RED environment variables.
- Real sending should start only with a one-recipient pilot.
- Keep Mailpit mode as the default until production approval is explicit.
