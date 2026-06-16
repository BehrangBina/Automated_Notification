const state = {
  contacts: [],
  deliveries: [],
  recipientGroups: [],
  schedules: [],
  meetingReminders: [],
  scheduleRuns: [],
  settings: null,
  pendingSend: null,
  pendingDeleteContact: null,
  pendingDeleteGroup: null,
  pendingDeleteReminder: null,
  lang: localStorage.getItem("parman-lang") || "en",
  currentView: "overview"
};

const i18n = {
  en: {
    "nav.overview": "Overview", "nav.meetings": "Meetings", "nav.birthdays": "Birthdays",
    "nav.notifications": "Notifications", "nav.groups": "Recipient groups",
    "nav.schedules": "Schedules", "nav.history": "Delivery history", "nav.settings": "Settings",
    "sidebar.safeMode": "Safe test mode", "sidebar.safeModeDetail": "Emails go to Mailpit",
    "topbar.openMailpit": "Open Mailpit",
    "common.safeMode": "Safe mode", "common.cancelEdit": "Cancel edit", "common.refresh": "Refresh",
    "common.fieldTimezone": "Timezone", "common.fieldRecipients": "Recipients",
    "overview.heroTitle": "Your automation tools, without the JSON.",
    "overview.heroSubtitle": "Create meetings, manage birthdays, send announcements, and review every delivery from one place.",
    "overview.statContacts": "Birthday contacts", "overview.statContactsSub": "Saved persistently",
    "overview.statSent": "Sent deliveries", "overview.statSentSub": "Confirmed by email service",
    "overview.statFailed": "Failed deliveries", "overview.statFailedSub": "Available for retry",
    "overview.statDuplicates": "Prevented duplicates", "overview.statDuplicatesSub": "Accidental resends stopped",
    "overview.quickStartEyebrow": "QUICK START", "overview.quickStartTitle": "What would you like to do?",
    "overview.qMeeting": "Meeting invite", "overview.qMeetingSub": "Agenda, timezones, Zoom and calendar file",
    "overview.qBirthday": "Birthday contact", "overview.qBirthdaySub": "Save people and run a safe birthday test",
    "overview.qNotification": "Announcement", "overview.qNotificationSub": "Persian or English branded notification",
    "overview.qGroups": "Recipient groups", "overview.qGroupsSub": "Reuse the same email lists across every message",
    "overview.qSchedules": "Schedules", "overview.qSchedulesSub": "Control automatic checks while staying in Mailpit mode",
    "overview.qSettings": "Safety settings", "overview.qSettingsSub": "Review safe mode and production-readiness basics",
    "meetings.eyebrow": "MEETING INVITATIONS", "meetings.title": "Create a global meeting",
    "meetings.subtitle": "Enter the meeting in its source timezone. Local times and the calendar attachment are generated automatically.",
    "meetings.safeBanner": "This meeting invite will be sent only to local Mailpit after preview approval.",
    "meetings.fieldTitle": "Meeting title", "meetings.fieldGreeting": "Greeting",
    "meetings.fieldDate": "Date", "meetings.fieldTime": "Start time",
    "meetings.fieldTimezone": "Source timezone", "meetings.fieldDuration": "Duration",
    "meetings.fieldAgenda": "Agenda", "meetings.fieldZoom": "Zoom URL",
    "meetings.fieldMeetingId": "Meeting ID", "meetings.fieldPasscode": "Passcode",
    "meetings.fieldOrgName": "Organizer name", "meetings.fieldOrgEmail": "Organizer email",
    "meetings.safeNote": "the invitation will appear in Mailpit.", "meetings.sendBtn": "Send test meeting invite",
    "birthdays.eyebrow": "BIRTHDAY AUTOMATION", "birthdays.title": "Birthday contacts",
    "birthdays.subtitle": "Saved contacts survive Node-RED restarts and are checked in their local timezone.",
    "birthdays.safeBanner": "Birthday tests require preview approval and go only to local Mailpit.",
    "birthdays.runTest": "Send selected birthday test", "birthdays.formTitle": "Add a birthday contact",
    "birthdays.fieldName": "Display name", "birthdays.fieldBirthday": "Birthday",
    "birthdays.fieldSendHour": "Local send hour", "birthdays.fieldRecipients": "Recipient emails",
    "birthdays.fieldActive": "Active contact", "birthdays.saveBtn": "Save contact",
    "birthdays.savedContacts": "Saved contacts", "birthdays.loadingContacts": "Loading contacts...",
    "notifications.eyebrow": "ANNOUNCEMENTS & REMINDERS", "notifications.title": "Compose a notification",
    "notifications.subtitle": "The layout automatically switches between Persian RTL and English LTR.",
    "notifications.safeBanner": "Email goes to local Mailpit. Telegram sends to your configured chat (set up in Settings).",
    "notifications.fieldLang": "Language", "notifications.fieldType": "Message type",
    "notifications.fieldSubject": "Email subject", "notifications.fieldHeadline": "Headline",
    "notifications.fieldMessage": "Message", "notifications.channelsEyebrow": "DELIVERY CHANNELS",
    "notifications.channelEmail": "Email (Mailpit in safe mode)",
    "notifications.channelTelegramHint": "(configure in Settings)",
    "notifications.safeNote": "the notification will appear in Mailpit.", "notifications.sendBtn": "Send test notification",
    "groups.eyebrow": "REUSABLE AUDIENCES", "groups.title": "Recipient groups",
    "groups.subtitle": "Manage email lists once, then add them to meetings, birthday messages, or notifications.",
    "groups.formTitle": "Create a recipient group", "groups.fieldName": "Group name",
    "groups.fieldDesc": "Description", "groups.fieldEmails": "Email addresses",
    "groups.saveBtn": "Save recipient group", "groups.savedGroups": "Saved groups", "groups.loading": "Loading recipient groups...",
    "schedules.eyebrow": "AUTOMATION TIMING", "schedules.title": "Schedules",
    "schedules.subtitle": "Control automatic checks safely. In this POC, scheduled emails still go only to Mailpit.",
    "schedules.refreshBtn": "Refresh schedules",
    "reminders.eyebrow": "MEETING REMINDERS", "reminders.title": "Scheduled reminders",
    "reminders.subtitle": "Create reminder emails that send once when their reminder time is due.",
    "reminders.runNow": "Run due reminders now", "reminders.formTitle": "Create meeting reminder",
    "reminders.fieldTitle": "Reminder title", "reminders.fieldTime": "Reminder time",
    "reminders.fieldMeetingDate": "Meeting date", "reminders.fieldMeetingTime": "Meeting time",
    "reminders.fieldMeetingTz": "Meeting timezone", "reminders.fieldZoom": "Zoom URL",
    "reminders.fieldMessage": "Reminder message", "reminders.fieldEnabled": "Enabled",
    "reminders.saveBtn": "Save reminder", "reminders.savedReminders": "Saved reminders", "reminders.loading": "Loading meeting reminders...",
    "runlog.eyebrow": "RUN AUDIT", "runlog.title": "Schedule run log",
    "runlog.subtitle": "See when automatic checks or manual test runs happened, and what they did.",
    "runlog.refreshBtn": "Refresh run log", "runlog.clearBtn": "Clear log",
    "history.eyebrow": "RELIABILITY", "history.title": "Delivery history",
    "history.subtitle": "Review sent, failed, queued, duplicate, and retry information.",
    "history.allStatuses": "All statuses", "history.sent": "Sent", "history.failed": "Failed", "history.queued": "Queued",
    "history.allSources": "All sources", "history.reliabilityTests": "Reliability tests",
    "history.colStatus": "Status", "history.colSource": "Source", "history.colSubject": "Subject",
    "history.colRecipients": "Recipients", "history.colAttempts": "Attempts",
    "history.colDuplicates": "Duplicates", "history.colUpdated": "Updated",
    "settings.eyebrow": "PRODUCTION READINESS", "settings.title": "Safety settings",
    "settings.subtitle": "Checkpoint 11A keeps live email disabled. This page documents the current safe-mode settings and what must be true before any future live-send phase.",
    "settings.operatorTitle": "Operator settings", "settings.fieldEnvName": "Environment name",
    "settings.fieldFromName": "Default from name", "settings.fieldFromEmail": "Default from email",
    "settings.fieldReplyTo": "Reply-to email", "settings.fieldApproval": "Future live-send approval phrase",
    "settings.fieldSmtpProvider": "SMTP provider", "settings.fieldSmtpHost": "SMTP host",
    "settings.fieldSmtpPort": "SMTP port", "settings.fieldSmtpUser": "SMTP username",
    "settings.fieldSenderDomain": "Sender domain",
    "settings.saveNote": "Live email remains locked off in this checkpoint.", "settings.saveBtn": "Save safety settings",
    "settings.readinessTitle": "Readiness checklist",
    "settings.preflightEyebrow": "SEND GUARDRAILS", "settings.preflightTitle": "Pre-flight checklist",
    "settings.preflightSubtitle": "These protections apply before POC messages are accepted for delivery.",
    "settings.preflightPanelTitle": "Active send protections", "settings.safeLabel": "safe",
    "telegram.eyebrow": "TELEGRAM NOTIFICATIONS", "telegram.title": "Telegram channel",
    "telegram.subtitle": "Connect a Telegram bot to send notifications directly to a chat alongside or instead of email.",
    "telegram.formTitle": "Telegram bot settings", "telegram.fieldToken": "Bot token",
    "telegram.fieldChatId": "Default chat ID", "telegram.saveBtn": "Save Telegram settings",
    "backup.eyebrow": "BACKUP & RESTORE", "backup.title": "Portable POC backup",
    "backup.subtitle": "Export the current local data as JSON, or paste a backup JSON to restore it. Restore keeps live email disabled.",
    "backup.exportTitle": "Export backup",
    "backup.exportDesc": "Includes contacts, recipient groups, reminders, settings, schedules, run logs, and delivery metadata.",
    "backup.exportNote": "The file stays on your computer.", "backup.exportBtn": "Download backup JSON",
    "backup.restoreTitle": "Restore backup", "backup.restoreField": "Backup JSON",
    "backup.restoreConfirm": "I understand this replaces saved POC data",
    "backup.restoreNote": "Live email remains locked off after restore.", "backup.restoreBtn": "Restore backup",
    "modals.deleteContactTitle": "Delete birthday contact?", "modals.keepContact": "Keep contact", "modals.deleteContact": "Delete contact",
    "modals.deleteGroupTitle": "Delete recipient group?", "modals.keepGroup": "Keep group", "modals.deleteGroup": "Delete group",
    "modals.deleteReminderTitle": "Delete reminder?", "modals.keepReminder": "Keep reminder", "modals.deleteReminder": "Delete reminder",
    "modals.safeModeConfirm": "Safe mode confirmation",
    "modals.safeModeConfirmDetail": "Review the recipients below. This POC will send to local Mailpit only.",
    "modals.goBack": "Go back and edit", "modals.confirmSend": "Confirm send to Mailpit"
  },
  fa: {
    "nav.overview": "\u062e\u0644\u0627\u0635\u0647", "nav.meetings": "\u062c\u0644\u0633\u0627\u062a", "nav.birthdays": "\u062a\u0648\u0644\u062f\u0647\u0627",
    "nav.notifications": "\u0627\u0637\u0644\u0627\u0639\u06cc\u0647\u200c\u0647\u0627", "nav.groups": "\u06af\u0631\u0648\u0647\u200c\u0647\u0627\u06cc \u06af\u06cc\u0631\u0646\u062f\u06af\u0627\u0646",
    "nav.schedules": "\u0628\u0631\u0646\u0627\u0645\u0647\u200c\u0647\u0627", "nav.history": "\u062a\u0627\u0631\u06cc\u062e\u0686\u0647 \u0627\u0631\u0633\u0627\u0644", "nav.settings": "\u062a\u0646\u0638\u06cc\u0645\u0627\u062a",
    "sidebar.safeMode": "\u062d\u0627\u0644\u062a \u0627\u06cc\u0645\u0646", "sidebar.safeModeDetail": "\u0627\u06cc\u0645\u06cc\u0644\u200c\u0647\u0627 \u0628\u0647 Mailpit \u0645\u06cc\u200c\u0631\u0648\u0646\u062f",
    "topbar.openMailpit": "\u0628\u0627\u0632 \u06a9\u0631\u062f\u0646 Mailpit",
    "common.safeMode": "\u062d\u0627\u0644\u062a \u0627\u06cc\u0645\u0646", "common.cancelEdit": "\u0644\u063a\u0648 \u0648\u06cc\u0631\u0627\u06cc\u0634", "common.refresh": "\u0628\u0647\u200c\u0631\u0648\u0632\u0631\u0633\u0627\u0646\u06cc",
    "common.fieldTimezone": "\u0645\u0646\u0637\u0642\u0647 \u0632\u0645\u0627\u0646\u06cc", "common.fieldRecipients": "\u06af\u06cc\u0631\u0646\u062f\u06af\u0627\u0646",
    "overview.heroTitle": "\u0627\u0628\u0632\u0627\u0631\u0647\u0627\u06cc \u0627\u062a\u0648\u0645\u0627\u0633\u06cc\u0648\u0646 \u067e\u0627\u0631\u0645\u0627\u0646\u060c \u0628\u062f\u0648\u0646 \u0646\u06cc\u0627\u0632 \u0628\u0647 JSON.",
    "overview.heroSubtitle": "\u062c\u0644\u0633\u0627\u062a \u0628\u06af\u0630\u0627\u0631\u06cc\u062f\u060c \u062a\u0648\u0644\u062f\u0647\u0627 \u0645\u062f\u06cc\u0631\u06cc\u062a \u06a9\u0646\u06cc\u062f\u060c \u0627\u0637\u0644\u0627\u0639\u06cc\u0647 \u0628\u0641\u0631\u0633\u062a\u06cc\u062f \u0648 \u0647\u0631 \u0627\u0631\u0633\u0627\u0644 \u0631\u0627 \u0628\u0631\u0631\u0633\u06cc \u06a9\u0646\u06cc\u062f.",
    "overview.statContacts": "\u0645\u062e\u0627\u0637\u0628\u06cc\u0646 \u062a\u0648\u0644\u062f", "overview.statContactsSub": "\u0630\u062e\u06cc\u0631\u0647\u200c\u0633\u0627\u0632\u06cc \u062f\u0627\u0626\u0645\u06cc",
    "overview.statSent": "\u0627\u0631\u0633\u0627\u0644\u200c\u0647\u0627\u06cc \u0645\u0648\u0641\u0642", "overview.statSentSub": "\u062a\u0623\u06cc\u06cc\u062f\u0634\u062f\u0647 \u062a\u0648\u0633\u0637 \u0633\u0631\u0648\u06cc\u0633 \u0627\u06cc\u0645\u06cc\u0644",
    "overview.statFailed": "\u0627\u0631\u0633\u0627\u0644\u200c\u0647\u0627\u06cc \u0646\u0627\u0645\u0648\u0641\u0642", "overview.statFailedSub": "\u0642\u0627\u0628\u0644 \u062a\u0644\u0627\u0634 \u0645\u062c\u062f\u062f",
    "overview.statDuplicates": "\u062a\u06a9\u0631\u0627\u0631\u06cc\u200c\u0647\u0627\u06cc \u062c\u0644\u0648\u06af\u06cc\u0631\u06cc\u200c\u0634\u062f\u0647", "overview.statDuplicatesSub": "\u0627\u0631\u0633\u0627\u0644\u200c\u0647\u0627\u06cc \u062a\u0635\u0627\u062f\u0641\u06cc \u0645\u062a\u0648\u0642\u0641 \u0634\u062f",
    "overview.quickStartEyebrow": "\u0634\u0631\u0648\u0639 \u0633\u0631\u06cc\u0639", "overview.quickStartTitle": "\u0686\u0647 \u06a9\u0627\u0631\u06cc \u0645\u06cc\u200c\u062e\u0648\u0627\u0647\u06cc\u062f \u0627\u0646\u062c\u0627\u0645 \u062f\u0647\u06cc\u062f\u061f",
    "overview.qMeeting": "\u062f\u0639\u0648\u062a\u200c\u0646\u0627\u0645\u0647 \u062c\u0644\u0633\u0647", "overview.qMeetingSub": "\u062f\u0633\u062a\u0648\u0631\u0627\u0644\u0639\u0645\u0644\u060c \u0645\u0646\u0627\u0637\u0642 \u0632\u0645\u0627\u0646\u06cc\u060c Zoom \u0648 \u0641\u0627\u06cc\u0644 \u062a\u0642\u0648\u06cc\u0645",
    "overview.qBirthday": "\u0645\u062e\u0627\u0637\u0628 \u062a\u0648\u0644\u062f", "overview.qBirthdaySub": "\u0627\u0641\u0631\u0627\u062f \u0631\u0627 \u0630\u062e\u06cc\u0631\u0647 \u06a9\u0646\u06cc\u062f \u0648 \u062a\u0633\u062a \u0627\u06cc\u0645\u0646 \u062a\u0648\u0644\u062f \u0627\u062c\u0631\u0627 \u06a9\u0646\u06cc\u062f",
    "overview.qNotification": "\u0627\u0637\u0644\u0627\u0639\u06cc\u0647", "overview.qNotificationSub": "\u0627\u0637\u0644\u0627\u0639\u06cc\u0647 \u0628\u0631\u0646\u062f\u062f\u0627\u0631 \u0628\u0647 \u0641\u0627\u0631\u0633\u06cc \u06cc\u0627 \u0627\u0646\u06af\u0644\u06cc\u0633\u06cc",
    "overview.qGroups": "\u06af\u0631\u0648\u0647\u200c\u0647\u0627\u06cc \u06af\u06cc\u0631\u0646\u062f\u06af\u0627\u0646", "overview.qGroupsSub": "\u0644\u06cc\u0633\u062a\u200c\u0647\u0627\u06cc \u0627\u06cc\u0645\u06cc\u0644 \u0631\u0627 \u06cc\u06a9\u200c\u0628\u0627\u0631 \u062a\u0639\u0631\u06cc\u0641 \u06a9\u0646\u06cc\u062f \u0648 \u062f\u0631 \u0647\u0645\u0647 \u062c\u0627 \u0627\u0633\u062a\u0641\u0627\u062f\u0647 \u06a9\u0646\u06cc\u062f",
    "overview.qSchedules": "\u0628\u0631\u0646\u0627\u0645\u0647\u200c\u0647\u0627", "overview.qSchedulesSub": "\u0628\u0631\u0631\u0633\u06cc\u200c\u0647\u0627\u06cc \u062e\u0648\u062f\u06a9\u0627\u0631 \u0631\u0627 \u0627\u06cc\u0645\u0646 \u06a9\u0646\u062a\u0631\u0644 \u06a9\u0646\u06cc\u062f",
    "overview.qSettings": "\u062a\u0646\u0638\u06cc\u0645\u0627\u062a \u0627\u06cc\u0645\u0646\u06cc\u062a", "overview.qSettingsSub": "\u062d\u0627\u0644\u062a \u0627\u06cc\u0645\u0646 \u0648 \u0622\u0645\u0627\u062f\u06af\u06cc \u062a\u0648\u0644\u06cc\u062f \u0631\u0627 \u0628\u0631\u0631\u0633\u06cc \u06a9\u0646\u06cc\u062f",
    "meetings.eyebrow": "\u062f\u0639\u0648\u062a\u200c\u0646\u0627\u0645\u0647\u200c\u0647\u0627\u06cc \u062c\u0644\u0633\u0647", "meetings.title": "\u0627\u06cc\u062c\u0627\u062f \u062c\u0644\u0633\u0647 \u0628\u06cc\u0646\u200c\u0627\u0644\u0645\u0644\u0644\u06cc",
    "meetings.subtitle": "\u062c\u0644\u0633\u0647 \u0631\u0627 \u062f\u0631 \u0645\u0646\u0637\u0642\u0647 \u0632\u0645\u0627\u0646\u06cc \u0645\u0628\u062f\u0627 \u0648\u0627\u0631\u062f \u06a9\u0646\u06cc\u062f\u060c \u0633\u0627\u0639\u062a \u0645\u062d\u0644\u06cc \u0648 \u0641\u0627\u06cc\u0644 \u062a\u0642\u0648\u06cc\u0645 \u062e\u0648\u062f\u06a9\u0627\u0631 \u0633\u0627\u062e\u062a\u0647 \u0645\u06cc\u200c\u0634\u0648\u0646\u062f.",
    "meetings.safeBanner": "\u0627\u06cc\u0646 \u062f\u0639\u0648\u062a\u200c\u0646\u0627\u0645\u0647 \u0641\u0642\u0637 \u062f\u0631 Mailpit \u0646\u0645\u0627\u06cc\u0634 \u062f\u0627\u062f\u0647 \u0645\u06cc\u200c\u0634\u0648\u062f.",
    "meetings.fieldTitle": "\u0639\u0646\u0648\u0627\u0646 \u062c\u0644\u0633\u0647", "meetings.fieldGreeting": "\u062e\u0637\u0627\u0628", "meetings.fieldDate": "\u062a\u0627\u0631\u06cc\u062e",
    "meetings.fieldTime": "\u0633\u0627\u0639\u062a \u0634\u0631\u0648\u0639", "meetings.fieldTimezone": "\u0645\u0646\u0637\u0642\u0647 \u0632\u0645\u0627\u0646\u06cc \u0645\u0628\u062f\u0627", "meetings.fieldDuration": "\u0645\u062f\u062a",
    "meetings.fieldAgenda": "\u062f\u0633\u062a\u0648\u0631\u0627\u0644\u0639\u0645\u0644", "meetings.fieldZoom": "Zoom URL", "meetings.fieldMeetingId": "\u0634\u0646\u0627\u0633\u0647 \u062c\u0644\u0633\u0647", "meetings.fieldPasscode": "\u0631\u0645\u0632 \u0639\u0628\u0648\u0631",
    "meetings.fieldOrgName": "\u0646\u0627\u0645 \u0628\u0631\u06af\u0632\u0627\u0631\u06a9\u0646\u0646\u062f\u0647", "meetings.fieldOrgEmail": "\u0627\u06cc\u0645\u06cc\u0644 \u0628\u0631\u06af\u0632\u0627\u0631\u06a9\u0646\u0646\u062f\u0647",
    "meetings.safeNote": "\u062f\u0639\u0648\u062a\u200c\u0646\u0627\u0645\u0647 \u062f\u0631 Mailpit \u0646\u0645\u0627\u06cc\u0634 \u062f\u0627\u062f\u0647 \u0645\u06cc\u200c\u0634\u0648\u062f.", "meetings.sendBtn": "\u0627\u0631\u0633\u0627\u0644 \u0622\u0632\u0645\u0627\u06cc\u0634\u06cc \u062f\u0639\u0648\u062a\u200c\u0646\u0627\u0645\u0647",
    "birthdays.eyebrow": "\u0627\u062a\u0648\u0645\u0627\u0633\u06cc\u0648\u0646 \u062a\u0648\u0644\u062f", "birthdays.title": "\u0645\u062e\u0627\u0637\u0628\u06cc\u0646 \u062a\u0648\u0644\u062f",
    "birthdays.subtitle": "\u0645\u062e\u0627\u0637\u0628\u06cc\u0646 \u067e\u0633 \u0627\u0632 \u0631\u0627\u0647\u200c\u0627\u0646\u062f\u0627\u0632\u06cc \u0645\u062c\u062f\u062f Node-RED \u062d\u0641\u0638 \u0645\u06cc\u200c\u0634\u0648\u0646\u062f.",
    "birthdays.safeBanner": "\u062a\u0633\u062a \u062a\u0648\u0644\u062f \u0646\u06cc\u0627\u0632 \u0628\u0647 \u062a\u0623\u06cc\u06cc\u062f \u062f\u0627\u0631\u062f \u0648 \u0641\u0642\u0637 \u0628\u0647 Mailpit \u0645\u06cc\u200c\u0631\u0648\u062f.",
    "birthdays.runTest": "\u0627\u0631\u0633\u0627\u0644 \u062a\u0633\u062a \u062a\u0648\u0644\u062f \u0627\u0646\u062a\u062e\u0627\u0628\u06cc", "birthdays.formTitle": "\u0627\u0641\u0632\u0648\u062f\u0646 \u0645\u062e\u0627\u0637\u0628 \u062a\u0648\u0644\u062f",
    "birthdays.fieldName": "\u0646\u0627\u0645 \u0646\u0645\u0627\u06cc\u0634\u06cc", "birthdays.fieldBirthday": "\u062a\u0627\u0631\u06cc\u062e \u062a\u0648\u0644\u062f", "birthdays.fieldSendHour": "\u0633\u0627\u0639\u062a \u0627\u0631\u0633\u0627\u0644 \u0645\u062d\u0644\u06cc",
    "birthdays.fieldRecipients": "\u0627\u06cc\u0645\u06cc\u0644\u200c\u0647\u0627\u06cc \u06af\u06cc\u0631\u0646\u062f\u0647", "birthdays.fieldActive": "\u0645\u062e\u0627\u0637\u0628 \u0641\u0639\u0627\u0644",
    "birthdays.saveBtn": "\u0630\u062e\u06cc\u0631\u0647 \u0645\u062e\u0627\u0637\u0628", "birthdays.savedContacts": "\u0645\u062e\u0627\u0637\u0628\u06cc\u0646 \u0630\u062e\u06cc\u0631\u0647\u200c\u0634\u062f\u0647", "birthdays.loadingContacts": "\u062f\u0631 \u062d\u0627\u0644 \u0628\u0627\u0631\u06af\u0630\u0627\u0631\u06cc...",
    "notifications.eyebrow": "\u0627\u0639\u0644\u0627\u0646\u06cc\u0647\u200c\u0647\u0627 \u0648 \u06cc\u0627\u062f\u0622\u0648\u0631\u06cc\u200c\u0647\u0627", "notifications.title": "\u0627\u06cc\u062c\u0627\u062f \u0627\u0637\u0644\u0627\u0639\u06cc\u0647",
    "notifications.subtitle": "\u0686\u06cc\u062f\u0645\u0627\u0646 \u0628\u06cc\u0646 RTL \u0641\u0627\u0631\u0633\u06cc \u0648 LTR \u0627\u0646\u06af\u0644\u06cc\u0633\u06cc \u062a\u063a\u06cc\u06cc\u0631 \u0645\u06cc\u200c\u06a9\u0646\u062f.",
    "notifications.safeBanner": "\u0627\u06cc\u0645\u06cc\u0644 \u0628\u0647 Mailpit \u0645\u06cc\u200c\u0631\u0648\u062f. \u062a\u0644\u06af\u0631\u0627\u0645 \u0628\u0647 \u06af\u0641\u062a\u06af\u0648\u06cc \u067e\u06cc\u06a9\u0631\u0628\u0646\u062f\u06cc\u200c\u0634\u062f\u0647 \u0645\u06cc\u200c\u0631\u0648\u062f.",
    "notifications.fieldLang": "\u0632\u0628\u0627\u0646", "notifications.fieldType": "\u0646\u0648\u0639 \u067e\u06cc\u0627\u0645",
    "notifications.fieldSubject": "\u0645\u0648\u0636\u0648\u0639 \u0627\u06cc\u0645\u06cc\u0644", "notifications.fieldHeadline": "\u062a\u06cc\u062a\u0631 \u067e\u06cc\u0627\u0645",
    "notifications.fieldMessage": "\u0645\u062a\u0646 \u067e\u06cc\u0627\u0645", "notifications.channelsEyebrow": "\u06a9\u0627\u0646\u0627\u0644\u200c\u0647\u0627\u06cc \u0627\u0631\u0633\u0627\u0644",
    "notifications.channelEmail": "\u0627\u06cc\u0645\u06cc\u0644 (Mailpit \u062f\u0631 \u062d\u0627\u0644\u062a \u0627\u06cc\u0645\u0646)",
    "notifications.channelTelegramHint": "(\u062f\u0631 \u062a\u0646\u0638\u06cc\u0645\u0627\u062a \u067e\u06cc\u06a9\u0631\u0628\u0646\u062f\u06cc \u06a9\u0646\u06cc\u062f)",
    "notifications.safeNote": "\u0627\u0637\u0644\u0627\u0639\u06cc\u0647 \u062f\u0631 Mailpit \u0646\u0645\u0627\u06cc\u0634 \u062f\u0627\u062f\u0647 \u0645\u06cc\u200c\u0634\u0648\u062f.", "notifications.sendBtn": "\u0627\u0631\u0633\u0627\u0644 \u0622\u0632\u0645\u0627\u06cc\u0634\u06cc \u0627\u0637\u0644\u0627\u0639\u06cc\u0647",
    "groups.eyebrow": "\u0645\u062e\u0627\u0637\u0628\u06cc\u0646 \u062b\u0627\u0628\u062a", "groups.title": "\u06af\u0631\u0648\u0647\u200c\u0647\u0627\u06cc \u06af\u06cc\u0631\u0646\u062f\u06af\u0627\u0646",
    "groups.subtitle": "\u0644\u06cc\u0633\u062a\u200c\u0647\u0627\u06cc \u0627\u06cc\u0645\u06cc\u0644 \u0631\u0627 \u06cc\u06a9\u200c\u0628\u0627\u0631 \u062a\u0639\u0631\u06cc\u0641 \u06a9\u0646\u06cc\u062f\u060c \u062f\u0631 \u0647\u0645\u0647 \u062c\u0627 \u0627\u0633\u062a\u0641\u0627\u062f\u0647 \u0645\u062c\u062f\u062f \u06a9\u0646\u06cc\u062f.",
    "groups.formTitle": "\u0627\u06cc\u062c\u0627\u062f \u06af\u0631\u0648\u0647 \u06af\u06cc\u0631\u0646\u062f\u06af\u0627\u0646", "groups.fieldName": "\u0646\u0627\u0645 \u06af\u0631\u0648\u0647",
    "groups.fieldDesc": "\u062a\u0648\u0636\u06cc\u062d\u0627\u062a", "groups.fieldEmails": "\u0622\u062f\u0631\u0633\u200c\u0647\u0627\u06cc \u0627\u06cc\u0645\u06cc\u0644",
    "groups.saveBtn": "\u0630\u062e\u06cc\u0631\u0647 \u06af\u0631\u0648\u0647", "groups.savedGroups": "\u06af\u0631\u0648\u0647\u200c\u0647\u0627\u06cc \u0630\u062e\u06cc\u0631\u0647\u200c\u0634\u062f\u0647", "groups.loading": "\u062f\u0631 \u062d\u0627\u0644 \u0628\u0627\u0631\u06af\u0630\u0627\u0631\u06cc...",
    "schedules.eyebrow": "\u0632\u0645\u0627\u0646\u200c\u0628\u0646\u062f\u06cc \u0627\u062a\u0648\u0645\u0627\u0633\u06cc\u0648\u0646", "schedules.title": "\u0628\u0631\u0646\u0627\u0645\u0647\u200c\u0647\u0627",
    "schedules.subtitle": "\u0628\u0631\u0631\u0633\u06cc\u200c\u0647\u0627\u06cc \u062e\u0648\u062f\u06a9\u0627\u0631 \u0631\u0627 \u0627\u06cc\u0645\u0646 \u06a9\u0646\u062a\u0631\u0644 \u06a9\u0646\u06cc\u062f.", "schedules.refreshBtn": "\u0628\u0647\u200c\u0631\u0648\u0632\u0631\u0633\u0627\u0646\u06cc \u0628\u0631\u0646\u0627\u0645\u0647\u200c\u0647\u0627",
    "reminders.eyebrow": "\u06cc\u0627\u062f\u0622\u0648\u0631\u06cc\u200c\u0647\u0627\u06cc \u062c\u0644\u0633\u0647", "reminders.title": "\u06cc\u0627\u062f\u0622\u0648\u0631\u06cc\u200c\u0647\u0627\u06cc \u0628\u0631\u0646\u0627\u0645\u0647\u200c\u0631\u06cc\u0632\u06cc\u200c\u0634\u062f\u0647",
    "reminders.subtitle": "\u06cc\u0627\u062f\u0622\u0648\u0631\u06cc\u200c\u0647\u0627\u06cc\u06cc \u0627\u06cc\u062c\u0627\u062f \u06a9\u0646\u06cc\u062f \u06a9\u0647 \u062f\u0631 \u0632\u0645\u0627\u0646 \u0645\u0642\u0631\u0631 \u06cc\u06a9\u200c\u0628\u0627\u0631 \u0627\u0631\u0633\u0627\u0644 \u0645\u06cc\u200c\u0634\u0648\u0646\u062f.",
    "reminders.runNow": "\u0627\u062c\u0631\u0627\u06cc \u06cc\u0627\u062f\u0622\u0648\u0631\u06cc\u200c\u0647\u0627\u06cc \u0633\u0631\u0631\u0633\u06cc\u062f\u0647", "reminders.formTitle": "\u0627\u06cc\u062c\u0627\u062f \u06cc\u0627\u062f\u0622\u0648\u0631\u06cc \u062c\u0644\u0633\u0647",
    "reminders.fieldTitle": "\u0639\u0646\u0648\u0627\u0646 \u06cc\u0627\u062f\u0622\u0648\u0631\u06cc", "reminders.fieldTime": "\u0632\u0645\u0627\u0646 \u06cc\u0627\u062f\u0622\u0648\u0631\u06cc",
    "reminders.fieldMeetingDate": "\u062a\u0627\u0631\u06cc\u062e \u062c\u0644\u0633\u0647", "reminders.fieldMeetingTime": "\u0633\u0627\u0639\u062a \u062c\u0644\u0633\u0647",
    "reminders.fieldMeetingTz": "\u0645\u0646\u0637\u0642\u0647 \u0632\u0645\u0627\u0646\u06cc \u062c\u0644\u0633\u0647", "reminders.fieldZoom": "Zoom URL",
    "reminders.fieldMessage": "\u0645\u062a\u0646 \u06cc\u0627\u062f\u0622\u0648\u0631\u06cc", "reminders.fieldEnabled": "\u0641\u0639\u0627\u0644",
    "reminders.saveBtn": "\u0630\u062e\u06cc\u0631\u0647 \u06cc\u0627\u062f\u0622\u0648\u0631\u06cc", "reminders.savedReminders": "\u06cc\u0627\u062f\u0622\u0648\u0631\u06cc\u200c\u0647\u0627\u06cc \u0630\u062e\u06cc\u0631\u0647\u200c\u0634\u062f\u0647", "reminders.loading": "\u062f\u0631 \u062d\u0627\u0644 \u0628\u0627\u0631\u06af\u0630\u0627\u0631\u06cc...",
    "runlog.eyebrow": "\u062d\u0633\u0627\u0628\u0631\u0633\u06cc \u0627\u062c\u0631\u0627", "runlog.title": "\u06af\u0632\u0627\u0631\u0634 \u0627\u062c\u0631\u0627\u06cc \u0628\u0631\u0646\u0627\u0645\u0647",
    "runlog.subtitle": "\u0628\u0628\u06cc\u0646\u06cc\u062f \u0628\u0631\u0631\u0633\u06cc\u200c\u0647\u0627\u06cc \u062e\u0648\u062f\u06a9\u0627\u0631 \u0648 \u062f\u0633\u062a\u06cc \u0686\u0647 \u0632\u0645\u0627\u0646\u06cc \u0627\u0646\u062c\u0627\u0645 \u0634\u062f\u0646\u062f.",
    "runlog.refreshBtn": "\u0628\u0647\u200c\u0631\u0648\u0632\u0631\u0633\u0627\u0646\u06cc \u06af\u0632\u0627\u0631\u0634", "runlog.clearBtn": "\u067e\u0627\u06a9 \u06a9\u0631\u062f\u0646 \u06af\u0632\u0627\u0631\u0634",
    "history.eyebrow": "\u0642\u0627\u0628\u0644\u06cc\u062a \u0627\u0637\u0645\u06cc\u0646\u0627\u0646", "history.title": "\u062a\u0627\u0631\u06cc\u062e\u0686\u0647 \u0627\u0631\u0633\u0627\u0644",
    "history.subtitle": "\u0627\u0631\u0633\u0627\u0644\u200c\u0634\u062f\u0647\u060c \u0646\u0627\u0645\u0648\u0641\u0642\u060c \u062f\u0631 \u0635\u0641\u060c \u062a\u06a9\u0631\u0627\u0631\u06cc \u0648 \u062a\u0644\u0627\u0634 \u0645\u062c\u062f\u062f \u0631\u0627 \u0645\u0631\u0648\u0631 \u06a9\u0646\u06cc\u062f.",
    "history.allStatuses": "\u0647\u0645\u0647 \u0648\u0636\u0639\u06cc\u062a\u200c\u0647\u0627", "history.sent": "\u0627\u0631\u0633\u0627\u0644\u200c\u0634\u062f\u0647", "history.failed": "\u0646\u0627\u0645\u0648\u0641\u0642", "history.queued": "\u062f\u0631 \u0635\u0641",
    "history.allSources": "\u0647\u0645\u0647 \u0645\u0646\u0627\u0628\u0639", "history.reliabilityTests": "\u062a\u0633\u062a\u200c\u0647\u0627\u06cc \u0642\u0627\u0628\u0644\u06cc\u062a",
    "history.colStatus": "\u0648\u0636\u0639\u06cc\u062a", "history.colSource": "\u0645\u0646\u0628\u0639", "history.colSubject": "\u0645\u0648\u0636\u0648\u0639",
    "history.colRecipients": "\u06af\u06cc\u0631\u0646\u062f\u06af\u0627\u0646", "history.colAttempts": "\u062a\u0644\u0627\u0634\u200c\u0647\u0627", "history.colDuplicates": "\u062a\u06a9\u0631\u0627\u0631\u06cc\u200c\u0647\u0627", "history.colUpdated": "\u0628\u0647\u200c\u0631\u0648\u0632\u0634\u062f\u0647",
    "settings.eyebrow": "\u0622\u0645\u0627\u062f\u06af\u06cc \u062a\u0648\u0644\u06cc\u062f", "settings.title": "\u062a\u0646\u0638\u06cc\u0645\u0627\u062a \u0627\u06cc\u0645\u0646\u06cc\u062a",
    "settings.subtitle": "\u0627\u06cc\u0645\u06cc\u0644 \u0632\u0646\u062f\u0647 \u0647\u0645\u0686\u0646\u0627\u0646 \u063a\u06cc\u0631\u0641\u0639\u0627\u0644 \u0627\u0633\u062a. \u0627\u06cc\u0646 \u0635\u0641\u062d\u0647 \u062a\u0646\u0638\u06cc\u0645\u0627\u062a \u0627\u06cc\u0645\u0646\u06cc\u062a \u0631\u0627 \u0645\u0633\u062a\u0646\u062f \u0633\u0627\u0632\u06cc \u0645\u06cc\u200c\u06a9\u0646\u062f.",
    "settings.operatorTitle": "\u062a\u0646\u0638\u06cc\u0645\u0627\u062a \u0627\u067e\u0631\u0627\u062a\u0648\u0631", "settings.fieldEnvName": "\u0646\u0627\u0645 \u0645\u062d\u06cc\u0637",
    "settings.fieldFromName": "\u0646\u0627\u0645 \u0641\u0631\u0633\u062a\u0646\u062f\u0647", "settings.fieldFromEmail": "\u0627\u06cc\u0645\u06cc\u0644 \u0641\u0631\u0633\u062a\u0646\u062f\u0647",
    "settings.fieldReplyTo": "\u0627\u06cc\u0645\u06cc\u0644 \u067e\u0627\u0633\u062e", "settings.fieldApproval": "\u0639\u0628\u0627\u0631\u062a \u062a\u0623\u06cc\u06cc\u062f \u0627\u0631\u0633\u0627\u0644 \u0632\u0646\u062f\u0647",
    "settings.fieldSmtpProvider": "\u0633\u0631\u0648\u06cc\u0633\u062f\u0647\u0646\u062f\u0647 SMTP", "settings.fieldSmtpHost": "\u0633\u0631\u0648\u0631 SMTP",
    "settings.fieldSmtpPort": "\u067e\u0648\u0631\u062a SMTP", "settings.fieldSmtpUser": "\u0646\u0627\u0645 \u06a9\u0627\u0631\u0628\u0631\u06cc SMTP",
    "settings.fieldSenderDomain": "\u062f\u0627\u0645\u0646\u0647 \u0641\u0631\u0633\u062a\u0646\u062f\u0647",
    "settings.saveNote": "\u0627\u06cc\u0645\u06cc\u0644 \u0632\u0646\u062f\u0647 \u063a\u06cc\u0631\u0641\u0639\u0627\u0644 \u0645\u06cc\u200c\u0645\u0627\u0646\u062f.", "settings.saveBtn": "\u0630\u062e\u06cc\u0631\u0647 \u062a\u0646\u0638\u06cc\u0645\u0627\u062a",
    "settings.readinessTitle": "\u0644\u06cc\u0633\u062a \u0622\u0645\u0627\u062f\u06af\u06cc",
    "settings.preflightEyebrow": "\u06af\u0627\u0631\u062f\u0647\u0627\u06cc \u0627\u0631\u0633\u0627\u0644", "settings.preflightTitle": "\u0628\u0631\u0631\u0633\u06cc \u067e\u06cc\u0634 \u0627\u0632 \u067e\u0631\u0648\u0627\u0632",
    "settings.preflightSubtitle": "\u0627\u06cc\u0646 \u062d\u0641\u0627\u0638\u062a\u200c\u0647\u0627 \u0642\u0628\u0644 \u0627\u0632 \u067e\u0630\u06cc\u0631\u0634 \u067e\u06cc\u0627\u0645\u200c\u0647\u0627 \u0628\u0631\u0631\u0633\u06cc \u0645\u06cc\u200c\u0634\u0648\u0646\u062f.",
    "settings.preflightPanelTitle": "\u062d\u0641\u0627\u0638\u062a\u200c\u0647\u0627\u06cc \u0641\u0639\u0627\u0644 \u0627\u0631\u0633\u0627\u0644", "settings.safeLabel": "\u0627\u06cc\u0645\u0646",
    "telegram.eyebrow": "\u0627\u0637\u0644\u0627\u0639\u06cc\u0647\u200c\u0647\u0627\u06cc \u062a\u0644\u06af\u0631\u0627\u0645", "telegram.title": "\u06a9\u0627\u0646\u0627\u0644 \u062a\u0644\u06af\u0631\u0627\u0645",
    "telegram.subtitle": "\u06cc\u06a9 \u0628\u0627\u062a \u062a\u0644\u06af\u0631\u0627\u0645 \u0628\u0631\u0627\u06cc \u0627\u0631\u0633\u0627\u0644 \u0645\u0633\u062a\u0642\u06cc\u0645 \u0627\u0637\u0644\u0627\u0639\u06cc\u0647\u200c\u0647\u0627 \u0648\u0635\u0644 \u06a9\u0646\u06cc\u062f.",
    "telegram.formTitle": "\u062a\u0646\u0638\u06cc\u0645\u0627\u062a \u0628\u0627\u062a \u062a\u0644\u06af\u0631\u0627\u0645", "telegram.fieldToken": "\u062a\u0648\u06a9\u0646 \u0628\u0627\u062a",
    "telegram.fieldChatId": "\u0634\u0646\u0627\u0633\u0647 \u06af\u0641\u062a\u06af\u0648", "telegram.saveBtn": "\u0630\u062e\u06cc\u0631\u0647 \u062a\u0646\u0638\u06cc\u0645\u0627\u062a \u062a\u0644\u06af\u0631\u0627\u0645",
    "backup.eyebrow": "\u067e\u0634\u062a\u06cc\u0628\u0627\u0646\u200c\u06af\u06cc\u0631\u06cc \u0648 \u0628\u0627\u0632\u06af\u0631\u062f\u0627\u0646\u06cc", "backup.title": "\u067e\u0634\u062a\u06cc\u0628\u0627\u0646 \u0642\u0627\u0628\u0644 \u062d\u0645\u0644",
    "backup.subtitle": "\u062f\u0627\u062f\u0647\u200c\u0647\u0627\u06cc \u0641\u0639\u0644\u06cc \u0631\u0627 \u062e\u0631\u0648\u062c\u06cc \u06a9\u0646\u06cc\u062f\u060c \u06cc\u0627 \u0631\u0648\u06cc \u067e\u0634\u062a\u06cc\u0628\u0627\u0646 \u0642\u0628\u0644\u06cc \u0628\u0627\u0632\u06af\u0631\u062f\u0627\u0646\u06cc \u06a9\u0646\u06cc\u062f.",
    "backup.exportTitle": "\u062e\u0631\u0648\u062c\u06cc \u067e\u0634\u062a\u06cc\u0628\u0627\u0646",
    "backup.exportDesc": "\u0634\u0627\u0645\u0644 \u0645\u062e\u0627\u0637\u0628\u06cc\u0646\u060c \u06af\u0631\u0648\u0647\u200c\u0647\u0627\u060c \u06cc\u0627\u062f\u0622\u0648\u0631\u06cc\u200c\u0647\u0627\u060c \u062a\u0646\u0638\u06cc\u0645\u0627\u062a \u0648 \u062a\u0627\u0631\u06cc\u062e\u0686\u0647 \u0627\u0631\u0633\u0627\u0644.",
    "backup.exportNote": "\u0641\u0627\u06cc\u0644 \u0631\u0648\u06cc \u06a9\u0627\u0645\u067e\u06cc\u0648\u062a\u0631 \u0634\u0645\u0627 \u0645\u06cc\u200c\u0645\u0627\u0646\u062f.", "backup.exportBtn": "\u062f\u0627\u0646\u0644\u0648\u062f JSON \u067e\u0634\u062a\u06cc\u0628\u0627\u0646",
    "backup.restoreTitle": "\u0628\u0627\u0632\u06af\u0631\u062f\u0627\u0646\u06cc \u067e\u0634\u062a\u06cc\u0628\u0627\u0646", "backup.restoreField": "JSON \u067e\u0634\u062a\u06cc\u0628\u0627\u0646",
    "backup.restoreConfirm": "\u0645\u06cc\u200c\u062f\u0627\u0646\u0645 \u0627\u06cc\u0646 \u062f\u0627\u062f\u0647\u200c\u0647\u0627\u06cc \u0641\u0639\u0644\u06cc \u0631\u0627 \u062c\u0627\u06cc\u06af\u0632\u06cc\u0646 \u0645\u06cc\u200c\u06a9\u0646\u062f",
    "backup.restoreNote": "\u0627\u06cc\u0645\u06cc\u0644 \u0632\u0646\u062f\u0647 \u067e\u0633 \u0627\u0632 \u0628\u0627\u0632\u06af\u0631\u062f\u0627\u0646\u06cc \u0647\u0645\u0686\u0646\u0627\u0646 \u063a\u06cc\u0631\u0641\u0639\u0627\u0644 \u0645\u06cc\u200c\u0645\u0627\u0646\u062f.", "backup.restoreBtn": "\u0628\u0627\u0632\u06af\u0631\u062f\u0627\u0646\u06cc",
    "modals.deleteContactTitle": "\u062d\u0630\u0641 \u0645\u062e\u0627\u0637\u0628 \u062a\u0648\u0644\u062f\u061f", "modals.keepContact": "\u0646\u06af\u0647 \u062f\u0627\u0634\u062a\u0646", "modals.deleteContact": "\u062d\u0630\u0641 \u0645\u062e\u0627\u0637\u0628",
    "modals.deleteGroupTitle": "\u062d\u0630\u0641 \u06af\u0631\u0648\u0647 \u06af\u06cc\u0631\u0646\u062f\u06af\u0627\u0646\u061f", "modals.keepGroup": "\u0646\u06af\u0647 \u062f\u0627\u0634\u062a\u0646", "modals.deleteGroup": "\u062d\u0630\u0641 \u06af\u0631\u0648\u0647",
    "modals.deleteReminderTitle": "\u062d\u0630\u0641 \u06cc\u0627\u062f\u0622\u0648\u0631\u06cc\u061f", "modals.keepReminder": "\u0646\u06af\u0647 \u062f\u0627\u0634\u062a\u0646", "modals.deleteReminder": "\u062d\u0630\u0641 \u06cc\u0627\u062f\u0622\u0648\u0631\u06cc",
    "modals.safeModeConfirm": "\u062a\u0623\u06cc\u06cc\u062f \u062d\u0627\u0644\u062a \u0627\u06cc\u0645\u0646",
    "modals.safeModeConfirmDetail": "\u06af\u06cc\u0631\u0646\u062f\u06af\u0627\u0646 \u0631\u0627 \u0628\u0631\u0631\u0633\u06cc \u06a9\u0646\u06cc\u062f. \u0627\u06cc\u0646 POC \u0641\u0642\u0637 \u0628\u0647 Mailpit \u0645\u062d\u0644\u06cc \u0627\u0631\u0633\u0627\u0644 \u0645\u06cc\u200c\u06a9\u0646\u062f.",
    "modals.goBack": "\u0628\u0627\u0632\u06af\u0634\u062a \u0648 \u0648\u06cc\u0631\u0627\u06cc\u0634", "modals.confirmSend": "\u062a\u0623\u06cc\u06cc\u062f \u0627\u0631\u0633\u0627\u0644"
  }
};

function t(key) {
  return (i18n[state.lang] || i18n.en)[key] || (i18n.en[key] || key);
}

function applyLanguage(lang) {
  state.lang = lang;
  localStorage.setItem("parman-lang", lang);
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === "fa" ? "rtl" : "ltr";
  document.querySelectorAll("[data-i18n]").forEach(el => {
    const key = el.getAttribute("data-i18n");
    const text = t(key);
    if (el.tagName === "OPTION") { el.textContent = text; }
    else if (el.children.length === 0) { el.textContent = text; }
    else { el.childNodes.forEach(node => { if (node.nodeType === 3 && node.textContent.trim()) node.textContent = text; }); }
  });
  $("#lang-en")?.classList.toggle("active", lang === "en");
  $("#lang-fa")?.classList.toggle("active", lang === "fa");
  if (state.currentView) {
    const pt = $("#page-title");
    if (pt) pt.textContent = t("nav." + state.currentView) || "Parman Automation";
  }
}

function initLanguage() {
  applyLanguage(state.lang);
  $$("[data-lang]").forEach(btn => {
    btn.addEventListener("click", () => applyLanguage(btn.dataset.lang));
  });
}

if (location.port !== "1880") {
  location.replace(`http://localhost:1880/app/${location.hash || "#overview"}`);
}

const $ = (selector, parent = document) => parent.querySelector(selector);
const $$ = (selector, parent = document) => [...parent.querySelectorAll(selector)];
const SEND_APPROVAL_PHRASE = "SEND TO MAILPIT";

function splitLines(value) {
  return value.split(/\r?\n/).map(item => item.trim()).filter(Boolean);
}

function splitEmails(value) {
  return value.split(/[\r\n,;]+/).map(item => item.trim()).filter(Boolean);
}

function uniqueKey(prefix) {
  return `${prefix}-${new Date().toISOString().replace(/\D/g, "").slice(0, 14)}`;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function formatPreviewList(items) {
  return `<ul>${items.map(item => `<li>${escapeHtml(item)}</li>`).join("")}</ul>`;
}

function renderPreview(title, rows) {
  return `
    <div class="preview-title">${escapeHtml(title)}</div>
    <dl>
      ${rows.map(row => `
        <div>
          <dt>${escapeHtml(row.label)}</dt>
          <dd>${Array.isArray(row.value) ? formatPreviewList(row.value) : escapeHtml(row.value || "Not provided")}</dd>
        </div>`).join("")}
    </dl>`;
}

function openSendPreview(title, rows, confirmLabel, onConfirm, guardrail = {}) {
  state.pendingSend = { onConfirm, approvalPhrase: guardrail.approvalPhrase || SEND_APPROVAL_PHRASE };
  $("#send-preview-title").textContent = title;
  $("#send-preview-body").innerHTML = renderPreview(title, rows);
  $("#send-approval-phrase").textContent = state.pendingSend.approvalPhrase;
  $("#send-approval-input").value = "";
  $("#confirm-send-preview").textContent = confirmLabel || "Confirm send to Mailpit";
  $("#send-preview-modal").classList.remove("hidden");
  $("#send-approval-input").focus();
}

function closeSendPreview() {
  state.pendingSend = null;
  $("#send-preview-modal").classList.add("hidden");
}

async function confirmPendingSend() {
  if (!state.pendingSend) return;
  const typed = $("#send-approval-input").value.trim();
  if (typed !== state.pendingSend.approvalPhrase) {
    toast(`Type ${state.pendingSend.approvalPhrase} before sending.`, true);
    $("#send-approval-input").focus();
    return;
  }
  const button = $("#confirm-send-preview");
  const action = state.pendingSend.onConfirm;
  button.disabled = true;
  if (!button.dataset.label) button.dataset.label = button.textContent;
  button.textContent = "Sending...";
  try {
    await action();
    closeSendPreview();
  } finally {
    button.disabled = false;
    button.textContent = button.dataset.label || "Confirm send to Mailpit";
    delete button.dataset.label;
  }
}

async function api(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: { "content-type": "application/json; charset=utf-8", ...(options.headers || {}) }
  });
  const type = response.headers.get("content-type") || "";
  const data = type.includes("application/json") ? await response.json() : await response.text();
  if (!response.ok) {
    const message = data?.errors?.join(", ") || data?.message || `Request failed (${response.status})`;
    throw new Error(message);
  }
  return data;
}

function toast(message, isError = false) {
  const element = $("#toast");
  element.textContent = message;
  element.className = `toast show${isError ? " error" : ""}`;
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => element.className = "toast", 4200);
}

function setBusy(form, busy) {
  const button = form.querySelector('button[type="submit"]');
  if (!button) return;
  button.disabled = busy;
  if (!button.dataset.label) button.dataset.label = button.textContent;
  button.textContent = busy ? "Working..." : button.dataset.label;
}

function showView(name) {
  $$(".view").forEach(view => view.classList.toggle("active", view.id === `view-${name}`));
  $$(".nav-item").forEach(button => button.classList.toggle("active", button.dataset.view === name));
  state.currentView = name;
  $("#page-title").textContent = t("nav." + name) || "Parman Automation";
  $(".sidebar").classList.remove("open");
  if (name === "overview") loadOverview();
  if (name === "birthdays") loadContacts();
  if (name === "groups") loadRecipientGroups();
  if (name === "schedules") {
    loadSchedules();
    loadMeetingReminders();
    loadScheduleRuns();
  }
  if (name === "history") loadHistory();
  if (name === "settings") loadSettings();
  history.replaceState(null, "", `#${name}`);
}

function mergeEmails(current, added) {
  return [...new Set([...splitEmails(current), ...added].map(email => email.toLowerCase()))].join("\n");
}

function renderGroupSelects() {
  const options = [
    '<option value="">Choose a saved group</option>',
    ...state.recipientGroups.map(group =>
      `<option value="${escapeHtml(group.id)}">${escapeHtml(group.name)} (${group.emails.length})</option>`
    )
  ].join("");
  $$(".recipient-group-select").forEach(select => {
    const selected = select.value;
    select.innerHTML = options;
    if (state.recipientGroups.some(group => group.id === selected)) select.value = selected;
  });
}

async function loadRecipientGroups() {
  const container = $("#groups-list");
  try {
    const data = await api("/api/recipient-groups");
    state.recipientGroups = data.groups || [];
    renderGroupSelects();
    if (!state.recipientGroups.length) {
      container.innerHTML = '<div class="empty-state">No recipient groups saved yet.</div>';
      return;
    }
    container.innerHTML = state.recipientGroups.map(group => `
      <div class="group-card">
        <div>
          <strong>${escapeHtml(group.name)}</strong>
          <span>${escapeHtml(group.description || "No description")}</span>
          <small>${escapeHtml(group.emails.join(", "))}</small>
        </div>
        <div class="contact-actions">
          <button type="button" data-edit-group="${escapeHtml(group.id)}">Edit</button>
          <button class="delete-contact-button" type="button" data-delete-group="${escapeHtml(group.id)}">Delete</button>
        </div>
      </div>`).join("");
  } catch (error) {
    container.innerHTML = `<div class="empty-state">${escapeHtml(error.message)}</div>`;
  }
}

async function loadSchedules() {
  const container = $("#schedules-list");
  try {
    const data = await api("/api/schedules");
    state.schedules = data.schedules || [];
    if (!state.schedules.length) {
      container.innerHTML = '<div class="empty-state">No schedules are configured yet.</div>';
      return;
    }
    container.innerHTML = state.schedules.map(schedule => `
      <article class="schedule-card">
        <div>
          <span class="status ${schedule.enabled ? "sent" : "queued"}">${schedule.enabled ? "enabled" : "disabled"}</span>
          <h3>${escapeHtml(schedule.name)}</h3>
          <p>${escapeHtml(schedule.description)}</p>
          <small>Every ${escapeHtml(schedule.intervalMinutes)} minutes · Safe mode: ${schedule.safeMode ? "Mailpit only" : "off"}${schedule.nextRunEstimate ? ` · Next estimate: ${escapeHtml(new Date(schedule.nextRunEstimate).toLocaleString())}` : ""}</small>
        </div>
        <div class="schedule-actions">
          <button class="secondary-button" type="button" data-run-schedule="${escapeHtml(schedule.id)}">Run check now</button>
          <button class="${schedule.enabled ? "danger-button" : "primary-button"}" type="button" data-toggle-schedule="${escapeHtml(schedule.id)}" data-enabled="${schedule.enabled ? "false" : "true"}">${schedule.enabled ? "Disable" : "Enable"}</button>
        </div>
      </article>`).join("");
  } catch (error) {
    container.innerHTML = `<div class="empty-state">${escapeHtml(error.message)}</div>`;
  }
}

async function loadMeetingReminders() {
  const container = $("#reminders-list");
  try {
    const data = await api("/api/meeting-reminders");
    state.meetingReminders = data.reminders || [];
    if (!state.meetingReminders.length) {
      container.innerHTML = '<div class="empty-state">No meeting reminders saved yet.</div>';
      return;
    }
    container.innerHTML = state.meetingReminders.map(reminder => `
      <div class="reminder-card">
        <div>
          <span class="status ${reminder.status === "sent" ? "sent" : reminder.status === "due" ? "failed" : "queued"}">${escapeHtml(reminder.status)}</span>
          <strong>${escapeHtml(reminder.title)}</strong>
          <span>Reminder: ${escapeHtml(new Date(reminder.remindAt).toLocaleString())}</span>
          <small>${escapeHtml(reminder.recipients.join(", "))}${reminder.sentAt ? ` · Sent: ${escapeHtml(new Date(reminder.sentAt).toLocaleString())}` : ""}</small>
        </div>
        <div class="contact-actions">
          <button type="button" data-edit-reminder="${escapeHtml(reminder.id)}">Edit</button>
          <button class="delete-contact-button" type="button" data-delete-reminder="${escapeHtml(reminder.id)}">Delete</button>
        </div>
      </div>`).join("");
  } catch (error) {
    container.innerHTML = `<div class="empty-state">${escapeHtml(error.message)}</div>`;
  }
}

function formatRunSummary(summary = {}) {
  const entries = Object.entries(summary).filter(([, value]) =>
    value !== undefined && value !== null && !Array.isArray(value) && typeof value !== "object"
  );
  if (!entries.length) return '<span class="summary-chip">No summary details</span>';
  return entries.map(([key, value]) =>
    `<span class="summary-chip"><b>${escapeHtml(key)}</b>${escapeHtml(value)}</span>`
  ).join("");
}

async function loadScheduleRuns() {
  const container = $("#schedule-run-log");
  if (!container) return;
  container.innerHTML = '<div class="empty-state">Loading schedule run log...</div>';
  const filter = $("#schedule-run-filter")?.value || "";
  const query = new URLSearchParams({ limit: "50" });
  if (filter) query.set("job", filter);
  try {
    const data = await api(`/api/schedule-runs?${query}`);
    state.scheduleRuns = data.runs || [];
    if (!state.scheduleRuns.length) {
      container.innerHTML = '<div class="empty-state">No schedule runs recorded yet. Click a manual run button to create the first log.</div>';
      return;
    }
    container.innerHTML = state.scheduleRuns.map(run => `
      <article class="run-log-card">
        <div class="run-log-main">
          <span class="status ${run.status === "success" ? "sent" : run.status === "failed" ? "failed" : "queued"}">${escapeHtml(run.status)}</span>
          <strong>${escapeHtml(run.name || run.job)}</strong>
          <span>${escapeHtml(run.trigger || "unknown")} run · ${escapeHtml(new Date(run.ranAt).toLocaleString())}</span>
        </div>
        <div class="run-log-summary">${formatRunSummary(run.summary)}</div>
      </article>`).join("");
  } catch (error) {
    container.innerHTML = `<div class="empty-state">${escapeHtml(error.message)}</div>`;
  }
}

function renderReadiness(readiness = []) {
  const container = $("#readiness-list");
  if (!readiness.length) {
    container.innerHTML = '<div class="empty-state">No readiness checks returned.</div>';
    return;
  }
  container.innerHTML = readiness.map(item => `
    <div class="readiness-item">
      <span class="readiness-dot ${item.ok ? "ok" : "blocked"}"></span>
      <div>
        <strong>${escapeHtml(item.label)}</strong>
        <span>${escapeHtml(item.detail)}</span>
      </div>
    </div>`).join("");
}

function renderPreflightChecklist() {
  const container = $("#preflight-list");
  if (!container) return;
  const items = [
    { ok: true, label: "Safe mode badge is visible", detail: "Send screens show that emails are routed to local Mailpit." },
    { ok: true, label: "Preview is required", detail: "Meeting, birthday test, and notification sends open a review modal first." },
    { ok: true, label: "Approval phrase is required", detail: `The sender must type ${SEND_APPROVAL_PHRASE} before confirming.` },
    { ok: true, label: "Live email remains blocked", detail: "Settings and restore force live email off and keep Mailpit as transport." }
  ];
  container.innerHTML = items.map(item => `
    <div class="readiness-item">
      <span class="readiness-dot ${item.ok ? "ok" : "blocked"}"></span>
      <div>
        <strong>${escapeHtml(item.label)}</strong>
        <span>${escapeHtml(item.detail)}</span>
      </div>
    </div>`).join("");
}

function renderBackupSummary(backup) {
  const container = $("#backup-summary");
  if (!container) return;
  if (!backup) {
    container.innerHTML = '<div class="empty-state">No backup loaded yet.</div>';
    return;
  }
  const counts = backup.counts || {};
  const exportedAt = backup.exportedAt ? new Date(backup.exportedAt).toLocaleString() : "Not exported yet";
  container.innerHTML = `
    <div class="backup-grid">
      <span><b>Exported</b>${escapeHtml(exportedAt)}</span>
      <span><b>Birthday contacts</b>${escapeHtml(counts.birthdayContacts || 0)}</span>
      <span><b>Recipient groups</b>${escapeHtml(counts.recipientGroups || 0)}</span>
      <span><b>Meeting reminders</b>${escapeHtml(counts.meetingReminders || 0)}</span>
      <span><b>Run logs</b>${escapeHtml(counts.scheduleRunLog || 0)}</span>
      <span><b>Delivery records</b>${escapeHtml(counts.deliveryHistory || 0)}</span>
    </div>`;
}

function downloadJson(filename, data) {
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

async function loadSettings() {
  const form = $("#settings-form");
  const list = $("#readiness-list");
  if (!form || !list) return;
  list.innerHTML = '<div class="empty-state">Loading settings...</div>';
  try {
    const data = await api("/api/settings");
    state.settings = data.settings;
    form.elements.environmentName.value = data.settings.environmentName || "";
    form.elements.defaultFromName.value = data.settings.defaultFromName || "";
    form.elements.defaultFromEmail.value = data.settings.defaultFromEmail || "";
    form.elements.replyToEmail.value = data.settings.replyToEmail || "";
    form.elements.approvalPhrase.value = data.settings.approvalPhrase || "";
    form.elements.smtpProvider.value = data.settings.smtpProvider || "";
    form.elements.smtpHost.value = data.settings.smtpHost || "";
    form.elements.smtpPort.value = data.settings.smtpPort || "";
    form.elements.smtpUsername.value = data.settings.smtpUsername || "";
    form.elements.senderDomain.value = data.settings.senderDomain || "";
    $("#safe-mode-title").textContent = data.settings.safeMode ? "Safe mode is active" : "Safe mode is off";
    $("#safe-mode-detail").textContent = `${data.settings.environmentName} · ${data.settings.emailTransport} · Live email ${data.settings.liveEmailEnabled ? "enabled" : "disabled"}`;
    renderReadiness(data.readiness || []);
    renderPreflightChecklist();
    renderBackupSummary(null);
  } catch (error) {
    list.innerHTML = `<div class="empty-state">${escapeHtml(error.message)}</div>`;
  }
  await loadTelegramSettings();
}

async function loadTelegramSettings() {
  const statusEl = $("#telegram-settings-status");
  const form = $("#telegram-settings-form");
  if (!statusEl || !form) return;
  try {
    const data = await api("/api/settings/telegram");
    const tg = data.telegram || {};
    if (tg.botTokenConfigured && tg.defaultChatId) {
      statusEl.textContent = `Configured. Chat ID: ${tg.defaultChatId}`;
      const hint = $("#telegram-channel-hint");
      if (hint) hint.textContent = "(configured)";
    } else if (tg.botTokenConfigured) {
      statusEl.textContent = "Bot token saved. Chat ID not set.";
    } else {
      statusEl.textContent = "Not configured.";
    }
    form.elements.telegramChatId.value = tg.defaultChatId || "";
  } catch {
    statusEl.textContent = "Could not load Telegram settings.";
  }
}

function editRecipientGroup(id) {
  const group = state.recipientGroups.find(item => item.id === id);
  if (!group) return;
  const form = $("#recipient-group-form");
  form.elements.id.value = group.id;
  form.elements.name.value = group.name;
  form.elements.description.value = group.description || "";
  form.elements.emails.value = group.emails.join("\n");
  $("#recipient-group-form-title").textContent = "Edit recipient group";
  $("#cancel-group-edit").classList.remove("hidden");
  form.scrollIntoView({ behavior: "smooth", block: "start" });
}

function resetRecipientGroupForm() {
  const form = $("#recipient-group-form");
  form.reset();
  form.elements.id.value = "";
  $("#recipient-group-form-title").textContent = "Create a recipient group";
  $("#cancel-group-edit").classList.add("hidden");
}

function openDeleteGroup(id) {
  const group = state.recipientGroups.find(item => item.id === id);
  if (!group) return;
  state.pendingDeleteGroup = group;
  $("#delete-group-message").textContent = `${group.name} and its ${group.emails.length} saved email address(es) will be removed.`;
  $("#delete-group-modal").classList.remove("hidden");
  $("#confirm-group-delete").focus();
}

function closeDeleteGroup() {
  state.pendingDeleteGroup = null;
  $("#delete-group-modal").classList.add("hidden");
}

function editMeetingReminder(id) {
  const reminder = state.meetingReminders.find(item => item.id === id);
  if (!reminder) return;
  const form = $("#meeting-reminder-form");
  form.elements.id.value = reminder.id;
  form.elements.title.value = reminder.title;
  form.elements.remindAt.value = reminder.remindAt.slice(0, 16);
  form.elements.meetingDate.value = reminder.meetingDate || "";
  form.elements.meetingTime.value = reminder.meetingTime || "";
  form.elements.meetingTimezone.value = reminder.meetingTimezone || "Europe/Paris";
  form.elements.zoomUrl.value = reminder.zoomUrl || "";
  form.elements.recipients.value = reminder.recipients.join("\n");
  form.elements.message.value = reminder.message || "";
  form.elements.enabled.checked = reminder.enabled !== false;
  $("#meeting-reminder-form-title").textContent = "Edit meeting reminder";
  $("#cancel-reminder-edit").classList.remove("hidden");
  form.scrollIntoView({ behavior: "smooth", block: "start" });
}

function resetMeetingReminderForm() {
  const form = $("#meeting-reminder-form");
  form.reset();
  form.elements.id.value = "";
  form.elements.recipients.value = "members@parman.local";
  form.elements.message.value = "This is a friendly reminder for the upcoming meeting.";
  form.elements.enabled.checked = true;
  $("#meeting-reminder-form-title").textContent = "Create meeting reminder";
  $("#cancel-reminder-edit").classList.add("hidden");
}

function openDeleteReminder(id) {
  const reminder = state.meetingReminders.find(item => item.id === id);
  if (!reminder) return;
  state.pendingDeleteReminder = reminder;
  $("#delete-reminder-message").textContent = `${reminder.title} will be permanently removed.`;
  $("#delete-reminder-modal").classList.remove("hidden");
  $("#confirm-reminder-delete").focus();
}

function closeDeleteReminder() {
  state.pendingDeleteReminder = null;
  $("#delete-reminder-modal").classList.add("hidden");
}

async function deleteMeetingReminder() {
  const reminder = state.pendingDeleteReminder;
  if (!reminder) return;
  const button = $("#confirm-reminder-delete");
  button.disabled = true;
  button.textContent = "Deleting...";
  try {
    await api(`/api/meeting-reminders/${encodeURIComponent(reminder.id)}`, { method: "DELETE" });
    if ($("#meeting-reminder-form").elements.id.value === reminder.id) resetMeetingReminderForm();
    closeDeleteReminder();
    toast(`${reminder.title} was deleted.`);
    await loadMeetingReminders();
  } catch (error) {
    toast(error.message, true);
  } finally {
    button.disabled = false;
    button.textContent = "Delete reminder";
  }
}

async function deleteRecipientGroup() {
  const group = state.pendingDeleteGroup;
  if (!group) return;
  const button = $("#confirm-group-delete");
  button.disabled = true;
  button.textContent = "Deleting...";
  try {
    await api(`/api/recipient-groups/${encodeURIComponent(group.id)}`, { method: "DELETE" });
    if ($("#recipient-group-form").elements.id.value === group.id) resetRecipientGroupForm();
    closeDeleteGroup();
    toast(`${group.name} was deleted.`);
    await loadRecipientGroups();
  } catch (error) {
    toast(error.message, true);
  } finally {
    button.disabled = false;
    button.textContent = "Delete group";
  }
}

async function loadOverview() {
  try {
    const [contacts, historyData] = await Promise.all([
      api("/api/birthdays/contacts"),
      api("/api/deliveries?limit=200")
    ]);
    const deliveries = historyData.deliveries || [];
    $("#stat-contacts").textContent = contacts.count;
    $("#stat-sent").textContent = deliveries.filter(item => item.status === "sent").length;
    $("#stat-failed").textContent = deliveries.filter(item => item.status === "failed").length;
    $("#stat-duplicates").textContent = deliveries.reduce((sum, item) => sum + (item.duplicateCount || 0), 0);
    $("#health-pill").innerHTML = "<i></i>Node-RED connected";
    $("#health-pill").classList.remove("error");
  } catch (error) {
    $("#health-pill").innerHTML = "<i></i>Service unavailable";
    $("#health-pill").classList.add("error");
  }
}

async function loadContacts() {
  const container = $("#contacts-list");
  try {
    const data = await api("/api/birthdays/contacts");
    state.contacts = data.contacts || [];
    if (!state.contacts.length) {
      container.innerHTML = '<div class="empty-state">No contacts saved yet.</div>';
      return;
    }
    container.innerHTML = state.contacts.map(contact => `
      <div class="contact-card">
        <input class="contact-select" type="checkbox" value="${escapeHtml(contact.id)}" aria-label="Select ${escapeHtml(contact.name)}">
        <div><strong>${escapeHtml(contact.name)}</strong><span>${escapeHtml(contact.birthday)} · ${escapeHtml(contact.timezone)} · ${escapeHtml(contact.sendHour)}:00 · ${contact.active ? "Active" : "Inactive"}</span></div>
        <div class="contact-actions">
          <button type="button" data-edit-contact="${escapeHtml(contact.id)}">Edit</button>
          <button class="delete-contact-button" type="button" data-delete-contact="${escapeHtml(contact.id)}">Delete</button>
        </div>
      </div>`).join("");
  } catch (error) {
    container.innerHTML = `<div class="empty-state">${escapeHtml(error.message)}</div>`;
  }
}

function editContact(id) {
  const contact = state.contacts.find(item => item.id === id);
  if (!contact) return;
  const form = $("#birthday-form");
  form.elements.id.value = contact.id;
  form.elements.name.value = contact.name;
  form.elements.birthday.value = contact.birthday;
  form.elements.timezone.value = contact.timezone;
  form.elements.sendHour.value = contact.sendHour;
  form.elements.recipientEmails.value = contact.recipientEmails.join("\n");
  form.elements.active.checked = contact.active;
  $("#birthday-form-title").textContent = "Edit birthday contact";
  $("#cancel-birthday-edit").classList.remove("hidden");
  form.scrollIntoView({ behavior: "smooth", block: "start" });
}

function resetBirthdayForm() {
  const form = $("#birthday-form");
  form.reset();
  form.elements.id.value = "";
  form.elements.sendHour.value = "9";
  form.elements.timezone.value = "Australia/Melbourne";
  form.elements.recipientEmails.value = "members@parman.local";
  form.elements.active.checked = true;
  $("#birthday-form-title").textContent = "Add a birthday contact";
  $("#cancel-birthday-edit").classList.add("hidden");
}

function openDeleteContact(id) {
  const contact = state.contacts.find(item => item.id === id);
  if (!contact) return;
  state.pendingDeleteContact = contact;
  $("#delete-contact-message").textContent = `${contact.name} will be permanently removed from birthday automation.`;
  $("#delete-contact-modal").classList.remove("hidden");
  $("#confirm-contact-delete").focus();
}

function closeDeleteContact() {
  state.pendingDeleteContact = null;
  $("#delete-contact-modal").classList.add("hidden");
}

async function deleteContact() {
  const contact = state.pendingDeleteContact;
  if (!contact) return;
  const button = $("#confirm-contact-delete");
  button.disabled = true;
  button.textContent = "Deleting...";
  try {
    await api(`/api/birthdays/contacts/${encodeURIComponent(contact.id)}`, { method: "DELETE" });
    if ($("#birthday-form").elements.id.value === contact.id) resetBirthdayForm();
    closeDeleteContact();
    toast(`${contact.name} was deleted.`);
    await Promise.all([loadContacts(), loadOverview()]);
  } catch (error) {
    toast(error.message, true);
  } finally {
    button.disabled = false;
    button.textContent = "Delete contact";
  }
}

async function loadHistory() {
  const body = $("#history-body");
  body.innerHTML = '<tr><td colspan="8">Loading delivery history...</td></tr>';
  const status = $("#history-status").value;
  const source = $("#history-source").value;
  const query = new URLSearchParams({ limit: "100" });
  if (status) query.set("status", status);
  if (source) query.set("source", source);
  try {
    const data = await api(`/api/deliveries?${query}`);
    state.deliveries = data.deliveries || [];
    if (!state.deliveries.length) {
      body.innerHTML = '<tr><td colspan="8">No deliveries match these filters.</td></tr>';
      return;
    }
    body.innerHTML = state.deliveries.map(item => `
      <tr>
        <td><span class="status ${escapeHtml(item.status)}">${escapeHtml(item.status)}</span></td>
        <td>${escapeHtml(item.source)}</td>
        <td>${escapeHtml(item.subject)}</td>
        <td>${escapeHtml(item.recipients.join(", "))}</td>
        <td>${escapeHtml(item.attempts)}</td>
        <td>${escapeHtml(item.duplicateCount || 0)}</td>
        <td>${escapeHtml(new Date(item.updatedAt).toLocaleString())}</td>
        <td>${item.status === "failed" ? `<button class="retry-button" data-retry="${escapeHtml(item.id)}">Retry</button>` : ""}</td>
      </tr>`).join("");
  } catch (error) {
    body.innerHTML = `<tr><td colspan="8">${escapeHtml(error.message)}</td></tr>`;
  }
}

$("#meeting-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  const values = Object.fromEntries(new FormData(form));
  const payload = {
    title: values.title,
    date: values.date,
    time: values.time,
    timezone: values.timezone,
    durationMinutes: Number(values.durationMinutes),
    greeting: values.greeting,
    agenda: splitLines(values.agenda),
    zoomUrl: values.zoomUrl,
    meetingId: values.meetingId,
    passcode: values.passcode,
    idempotencyKey: uniqueKey("meeting"),
    organizer: { name: values.organizerName, email: values.organizerEmail },
    recipients: splitEmails(values.recipients),
    displayTimezones: [
      { label: "اروپای مرکزی", timezone: "Europe/Paris" },
      { label: "ملبورن", timezone: "Australia/Melbourne" },
      { label: "لندن", timezone: "Europe/London" },
      { label: "نیویورک", timezone: "America/New_York" }
    ]
  };
  openSendPreview("Review meeting invite", [
    { label: "Subject", value: `دعوت‌نامه: ${payload.title}` },
    { label: "Recipients", value: payload.recipients },
    { label: "Date", value: payload.date },
    { label: "Start time", value: `${payload.time} in ${payload.timezone}` },
    { label: "Duration", value: `${payload.durationMinutes} minutes` },
    { label: "Agenda", value: payload.agenda }
  ], "Confirm meeting send", async () => {
    try {
      await api("/api/meetings/send", { method: "POST", body: JSON.stringify(payload) });
      toast("Meeting invitation sent to Mailpit successfully.");
    } catch (error) {
      toast(error.message, true);
      throw error;
    }
  });
});

$("#birthday-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  setBusy(form, true);
  const values = Object.fromEntries(new FormData(form));
  const payload = {
    id: values.id || undefined,
    name: values.name,
    birthday: values.birthday,
    timezone: values.timezone,
    sendHour: Number(values.sendHour),
    recipientEmails: splitEmails(values.recipientEmails),
    active: form.elements.active.checked
  };
  try {
    await api("/api/birthdays/contacts", { method: "POST", body: JSON.stringify(payload) });
    toast(values.id ? "Birthday contact updated." : "Birthday contact saved.");
    resetBirthdayForm();
    await loadContacts();
    await loadOverview();
  } catch (error) {
    toast(error.message, true);
  } finally {
    setBusy(form, false);
  }
});

$("#recipient-group-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  setBusy(form, true);
  const values = Object.fromEntries(new FormData(form));
  const payload = {
    id: values.id || undefined,
    name: values.name,
    description: values.description,
    emails: splitEmails(values.emails)
  };
  try {
    await api("/api/recipient-groups", { method: "POST", body: JSON.stringify(payload) });
    toast(values.id ? "Recipient group updated." : "Recipient group saved.");
    resetRecipientGroupForm();
    await loadRecipientGroups();
  } catch (error) {
    toast(error.message, true);
  } finally {
    setBusy(form, false);
  }
});

$("#meeting-reminder-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  setBusy(form, true);
  const values = Object.fromEntries(new FormData(form));
  const payload = {
    id: values.id || undefined,
    title: values.title,
    remindAt: values.remindAt,
    meetingDate: values.meetingDate,
    meetingTime: values.meetingTime,
    meetingTimezone: values.meetingTimezone,
    zoomUrl: values.zoomUrl,
    recipients: splitEmails(values.recipients),
    message: values.message,
    enabled: form.elements.enabled.checked
  };
  try {
    await api("/api/meeting-reminders", { method: "POST", body: JSON.stringify(payload) });
    toast(values.id ? "Meeting reminder updated." : "Meeting reminder saved.");
    resetMeetingReminderForm();
    await loadMeetingReminders();
  } catch (error) {
    toast(error.message, true);
  } finally {
    setBusy(form, false);
  }
});

$("#settings-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  setBusy(form, true);
  const values = Object.fromEntries(new FormData(form));
  try {
    await api("/api/settings", { method: "POST", body: JSON.stringify(values) });
    toast("Safety settings saved. Live email is still disabled.");
    await loadSettings();
  } catch (error) {
    toast(error.message, true);
  } finally {
    setBusy(form, false);
  }
});

$("#telegram-settings-form")?.addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  setBusy(form, true);
  const values = Object.fromEntries(new FormData(form));
  try {
    await api("/api/settings/telegram", {
      method: "POST",
      body: JSON.stringify({ botToken: values.telegramBotToken, defaultChatId: values.telegramChatId })
    });
    form.elements.telegramBotToken.value = "";
    toast("Telegram settings saved.");
    await loadTelegramSettings();
  } catch (error) {
    toast(error.message, true);
  } finally {
    setBusy(form, false);
  }
});

$("#restore-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  setBusy(form, true);
  try {
    const backup = JSON.parse(form.elements.backupJson.value);
    const result = await api("/api/backups/restore", { method: "POST", body: JSON.stringify(backup) });
    toast(result.message || "Backup restored.");
    form.reset();
    await Promise.all([
      loadSettings(),
      loadContacts(),
      loadRecipientGroups(),
      loadMeetingReminders(),
      loadScheduleRuns(),
      loadHistory()
    ]);
  } catch (error) {
    toast(error.message, true);
  } finally {
    setBusy(form, false);
  }
});

$("#run-birthday-test").addEventListener("click", async event => {
  const selected = $$(".contact-select:checked").map(input => input.value);
  if (!selected.length) {
    toast("Select at least one birthday contact first.", true);
    return;
  }
  const contacts = selected.map(id => state.contacts.find(contact => contact.id === id)).filter(Boolean);
  openSendPreview("Review birthday test", [
    { label: "Selected contacts", value: contacts.map(contact => contact.name) },
    { label: "Recipients", value: [...new Set(contacts.flatMap(contact => contact.recipientEmails || []))] },
    { label: "Mode", value: "Forced safe test to Mailpit" }
  ], "Confirm birthday test", async () => {
    try {
      const result = await api("/api/birthdays/check", {
        method: "POST",
        body: JSON.stringify({ force: true, contactIds: selected, idempotencyKey: uniqueKey("birthday-test") })
      });
      toast(`${result.queuedContacts?.length || 0} birthday contact(s) sent to Mailpit.`);
    } catch (error) {
      toast(error.message, true);
      throw error;
    }
  });
});

$("#notification-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  const values = Object.fromEntries(new FormData(form));
  const action = values.actionLabel && values.actionUrl ? { label: values.actionLabel, url: values.actionUrl } : undefined;
  const channels = [];
  if (form.elements.channelEmail?.checked !== false) channels.push("email");
  if (form.elements.channelTelegram?.checked) channels.push("telegram");
  if (!channels.length) channels.push("email");
  const payload = {
    language: values.language,
    type: values.type,
    subject: values.subject,
    title: values.title,
    message: values.message,
    recipients: splitEmails(values.recipients),
    channels,
    idempotencyKey: uniqueKey("notification"),
    action
  };
  const channelLabel = channels.includes("telegram") && channels.includes("email") ? "Mailpit + Telegram" : channels.includes("telegram") ? "Telegram" : "Mailpit";
  openSendPreview("Review notification", [
    { label: "Subject", value: payload.subject },
    { label: "Headline", value: payload.title },
    { label: "Recipients", value: payload.recipients },
    { label: "Language", value: payload.language },
    { label: "Type", value: payload.type },
    { label: "Channels", value: channels },
    { label: "Message", value: payload.message }
  ], "Confirm notification send", async () => {
    try {
      await api("/api/notifications/send", { method: "POST", body: JSON.stringify(payload) });
      toast(`Notification sent to ${channelLabel}.`);
    } catch (error) {
      toast(error.message, true);
      throw error;
    }
  });
});

$("#history-body").addEventListener("click", async event => {
  const button = event.target.closest("[data-retry]");
  if (!button) return;
  button.disabled = true;
  try {
    await api(`/api/deliveries/${encodeURIComponent(button.dataset.retry)}/retry`, { method: "POST", body: "{}" });
    toast("Retry accepted.");
    setTimeout(loadHistory, 1600);
  } catch (error) {
    toast(error.message, true);
    button.disabled = false;
  }
});

$("#contacts-list").addEventListener("click", event => {
  const editButton = event.target.closest("[data-edit-contact]");
  const deleteButton = event.target.closest("[data-delete-contact]");
  if (editButton) editContact(editButton.dataset.editContact);
  if (deleteButton) openDeleteContact(deleteButton.dataset.deleteContact);
});

$("#groups-list").addEventListener("click", event => {
  const editButton = event.target.closest("[data-edit-group]");
  const deleteButton = event.target.closest("[data-delete-group]");
  if (editButton) editRecipientGroup(editButton.dataset.editGroup);
  if (deleteButton) openDeleteGroup(deleteButton.dataset.deleteGroup);
});

$("#schedules-list").addEventListener("click", async event => {
  const toggle = event.target.closest("[data-toggle-schedule]");
  const run = event.target.closest("[data-run-schedule]");
  if (toggle) {
    toggle.disabled = true;
    try {
      const enabled = toggle.dataset.enabled === "true";
      await api(`/api/schedules/${encodeURIComponent(toggle.dataset.toggleSchedule)}`, {
        method: "POST",
        body: JSON.stringify({ enabled })
      });
      toast(enabled ? "Schedule enabled." : "Schedule disabled.");
      await loadSchedules();
      await loadScheduleRuns();
    } catch (error) {
      toast(error.message, true);
      toggle.disabled = false;
    }
  }
  if (run) {
    run.disabled = true;
    try {
      const result = await api("/api/birthdays/check", { method: "POST", body: JSON.stringify({ force: false }) });
      toast(`Birthday check ran. Queued: ${result.queued || 0}.`);
      await loadScheduleRuns();
    } catch (error) {
      toast(error.message, true);
    } finally {
      run.disabled = false;
    }
  }
});

$("#reminders-list").addEventListener("click", event => {
  const editButton = event.target.closest("[data-edit-reminder]");
  const deleteButton = event.target.closest("[data-delete-reminder]");
  if (editButton) editMeetingReminder(editButton.dataset.editReminder);
  if (deleteButton) openDeleteReminder(deleteButton.dataset.deleteReminder);
});

$$(".apply-recipient-group").forEach(button => button.addEventListener("click", () => {
  const picker = button.closest(".group-picker");
  const groupId = $(".recipient-group-select", picker).value;
  const group = state.recipientGroups.find(item => item.id === groupId);
  if (!group) {
    toast("Choose a recipient group first.", true);
    return;
  }
  const form = document.getElementById(button.dataset.targetForm);
  const field = form.elements[button.dataset.targetField];
  field.value = mergeEmails(field.value, group.emails);
  toast(`${group.name} recipients added.`);
}));

$$(".nav-item").forEach(button => button.addEventListener("click", () => showView(button.dataset.view)));
$$("[data-go]").forEach(button => button.addEventListener("click", () => showView(button.dataset.go)));
$("#mobile-menu").addEventListener("click", () => $(".sidebar").classList.toggle("open"));
$("#refresh-contacts").addEventListener("click", loadContacts);
$("#cancel-birthday-edit").addEventListener("click", resetBirthdayForm);
$("#cancel-send-preview").addEventListener("click", closeSendPreview);
$("#confirm-send-preview").addEventListener("click", confirmPendingSend);
$("#send-preview-modal").addEventListener("click", event => {
  if (event.target === event.currentTarget) closeSendPreview();
});
$("#refresh-groups").addEventListener("click", loadRecipientGroups);
$("#refresh-schedules").addEventListener("click", loadSchedules);
$("#refresh-run-log").addEventListener("click", loadScheduleRuns);
$("#schedule-run-filter").addEventListener("change", loadScheduleRuns);
$("#clear-run-log").addEventListener("click", async event => {
  const button = event.currentTarget;
  button.disabled = true;
  try {
    await api("/api/schedule-runs", { method: "DELETE", body: "{}" });
    toast("Schedule run log cleared.");
    await loadScheduleRuns();
  } catch (error) {
    toast(error.message, true);
  } finally {
    button.disabled = false;
  }
});
$("#refresh-reminders").addEventListener("click", loadMeetingReminders);
$("#run-reminder-check").addEventListener("click", async event => {
  const button = event.currentTarget;
  button.disabled = true;
  try {
    const result = await api("/api/meeting-reminders/check", { method: "POST", body: "{}" });
    toast(`Meeting reminder check ran. Sent: ${result.sentCount || 0}.`);
    await loadMeetingReminders();
    await loadScheduleRuns();
  } catch (error) {
    toast(error.message, true);
  } finally {
    button.disabled = false;
  }
});
$("#cancel-reminder-edit").addEventListener("click", resetMeetingReminderForm);
$("#cancel-reminder-delete").addEventListener("click", closeDeleteReminder);
$("#confirm-reminder-delete").addEventListener("click", deleteMeetingReminder);
$("#delete-reminder-modal").addEventListener("click", event => {
  if (event.target === event.currentTarget) closeDeleteReminder();
});
$("#cancel-group-edit").addEventListener("click", resetRecipientGroupForm);
$("#cancel-group-delete").addEventListener("click", closeDeleteGroup);
$("#confirm-group-delete").addEventListener("click", deleteRecipientGroup);
$("#delete-group-modal").addEventListener("click", event => {
  if (event.target === event.currentTarget) closeDeleteGroup();
});
$("#cancel-contact-delete").addEventListener("click", closeDeleteContact);
$("#confirm-contact-delete").addEventListener("click", deleteContact);
$("#delete-contact-modal").addEventListener("click", event => {
  if (event.target === event.currentTarget) closeDeleteContact();
});
document.addEventListener("keydown", event => {
  if (event.key === "Escape" && !$("#send-preview-modal").classList.contains("hidden")) closeSendPreview();
  if (event.key === "Escape" && !$("#delete-contact-modal").classList.contains("hidden")) closeDeleteContact();
  if (event.key === "Escape" && !$("#delete-group-modal").classList.contains("hidden")) closeDeleteGroup();
  if (event.key === "Escape" && !$("#delete-reminder-modal").classList.contains("hidden")) closeDeleteReminder();
});
$("#refresh-history").addEventListener("click", loadHistory);
$("#history-status").addEventListener("change", loadHistory);
$("#history-source").addEventListener("change", loadHistory);
$("#refresh-settings").addEventListener("click", loadSettings);
$("#export-backup").addEventListener("click", async event => {
  const button = event.currentTarget;
  button.disabled = true;
  if (!button.dataset.label) button.dataset.label = button.textContent;
  button.textContent = "Exporting...";
  try {
    const backup = await api("/api/backups/export");
    renderBackupSummary(backup);
    const stamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
    downloadJson(`parman-poc-backup-${stamp}.json`, backup);
    toast("Backup JSON downloaded.");
  } catch (error) {
    toast(error.message, true);
  } finally {
    button.disabled = false;
    button.textContent = button.dataset.label || "Download backup JSON";
    delete button.dataset.label;
  }
});

loadRecipientGroups();
loadMeetingReminders();
initLanguage();
const initialView = location.hash.replace("#", "");
showView(["overview", "meetings", "birthdays", "notifications", "groups", "schedules", "history", "settings"].includes(initialView) ? initialView : "overview");
