$ErrorActionPreference = "Stop"

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object {
    $_.id -notmatch "^checkpoint10b-" -and
    $_.z -ne "checkpoint10b-tab"
})

$saveCode = @'
const input = msg.payload || {};
const errors = [];
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

if (typeof input.title !== 'string' || !input.title.trim()) errors.push('title is required');
const remindAt = new Date(input.remindAt || '');
if (Number.isNaN(remindAt.getTime())) errors.push('remindAt must be a valid date/time');
if (!Array.isArray(input.recipients) || input.recipients.length === 0 || input.recipients.some(email => typeof email !== 'string' || !emailPattern.test(email.trim()))) {
    errors.push('recipients must contain at least one valid email address');
}
if (input.zoomUrl && !/^https?:\/\//i.test(input.zoomUrl)) errors.push('zoomUrl must start with http or https');

msg.headers = { 'content-type': 'application/json; charset=utf-8' };
if (errors.length) {
    msg.statusCode = 400;
    msg.payload = { ok: false, errors };
    return msg;
}

const reminders = global.get('meetingReminders') || [];
const id = typeof input.id === 'string' && input.id.trim()
    ? input.id.trim()
    : `${Date.now()}-${Math.random().toString(16).slice(2)}`;
const now = new Date().toISOString();
const index = reminders.findIndex(item => item.id === id);
const created = index === -1;
const existing = created ? {} : reminders[index];
const reminder = {
    id,
    title: input.title.trim(),
    remindAt: remindAt.toISOString(),
    meetingDate: input.meetingDate || '',
    meetingTime: input.meetingTime || '',
    meetingTimezone: input.meetingTimezone || '',
    zoomUrl: input.zoomUrl || '',
    message: (input.message || '').trim(),
    recipients: [...new Set(input.recipients.map(email => email.trim().toLowerCase()))],
    enabled: input.enabled !== false,
    sentAt: input.resetSent ? null : (existing.sentAt || null),
    createdAt: existing.createdAt || now,
    updatedAt: now
};
if (created) reminders.push(reminder); else reminders[index] = reminder;
global.set('meetingReminders', reminders);

msg.statusCode = created ? 201 : 200;
msg.payload = { ok: true, created, reminder };
return msg;
'@

$listCode = @'
const reminders = global.get('meetingReminders') || [];
const now = Date.now();
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = {
    ok: true,
    count: reminders.length,
    reminders: reminders.slice().sort((a, b) => Date.parse(a.remindAt) - Date.parse(b.remindAt)).map(item => ({
        ...item,
        status: item.sentAt ? 'sent' : item.enabled === false ? 'disabled' : Date.parse(item.remindAt) <= now ? 'due' : 'scheduled'
    }))
};
return msg;
'@

$deleteCode = @'
const reminders = global.get('meetingReminders') || [];
const id = msg.req && msg.req.params ? msg.req.params.id : null;
const index = reminders.findIndex(item => item.id === id);
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
if (index === -1) {
    msg.statusCode = 404;
    msg.payload = { ok: false, errors: ['meeting reminder not found'] };
    return msg;
}
const [deleted] = reminders.splice(index, 1);
global.set('meetingReminders', reminders);
msg.statusCode = 200;
msg.payload = { ok: true, reminder: deleted, remainingCount: reminders.length };
return msg;
'@

$checkCode = @'
const isHttp = Boolean(msg.req && msg.res);
const options = msg.payload && typeof msg.payload === 'object' ? msg.payload : {};
const reminders = global.get('meetingReminders') || [];
const now = options.now ? new Date(options.now) : new Date();
const sent = [];
const skipped = [];
const emails = [];

function respond(statusCode, payload) {
    if (!isHttp) return null;
    return {
        ...msg,
        statusCode,
        headers: { 'content-type': 'application/json; charset=utf-8' },
        payload
    };
}

function escapeHtml(value) {
    return String(value || '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
}

if (Number.isNaN(now.getTime())) {
    return [null, respond(400, { ok: false, errors: ['now must be a valid date/time'] })];
}

for (const reminder of reminders) {
    if (reminder.enabled === false) {
        skipped.push({ id: reminder.id, title: reminder.title, reason: 'disabled' });
        continue;
    }
    if (reminder.sentAt) {
        skipped.push({ id: reminder.id, title: reminder.title, reason: 'already sent', sentAt: reminder.sentAt });
        continue;
    }
    if (Date.parse(reminder.remindAt) > now.getTime()) {
        skipped.push({ id: reminder.id, title: reminder.title, reason: 'not due' });
        continue;
    }

    const subject = `Reminder: ${reminder.title}`;
    const details = [
        reminder.meetingDate ? `Date: ${reminder.meetingDate}` : '',
        reminder.meetingTime ? `Time: ${reminder.meetingTime} ${reminder.meetingTimezone || ''}` : '',
        reminder.zoomUrl ? `Zoom: ${reminder.zoomUrl}` : ''
    ].filter(Boolean).join('<br>');
    const html = `
      <div style="font-family:Segoe UI,Tahoma,Arial,sans-serif;line-height:1.6;color:#202938;padding:24px;">
        <h2 style="color:#173b57;margin:0 0 14px;">${escapeHtml(subject)}</h2>
        <p>${escapeHtml(reminder.message || 'This is your scheduled meeting reminder.')}</p>
        <div style="margin:18px 0;padding:14px;border-left:4px solid #1473e6;background:#edf5ff;">${details}</div>
        ${reminder.zoomUrl ? `<p><a href="${escapeHtml(reminder.zoomUrl)}" style="display:inline-block;background:#1473e6;color:#fff;text-decoration:none;padding:12px 18px;border-radius:8px;font-weight:700;">Join meeting</a></p>` : ''}
        <p style="color:#697586;font-size:13px;">Sent safely by the POC automation system to Mailpit.</p>
      </div>`;

    emails.push({
        to: reminder.recipients.join(','),
        from: 'meeting-reminders@parman.local',
        topic: subject,
        payload: html
    });
    reminder.sentAt = now.toISOString();
    reminder.updatedAt = now.toISOString();
    sent.push({ id: reminder.id, title: reminder.title, recipients: reminder.recipients });
}

global.set('meetingReminders', reminders);
return [emails.length ? emails : null, respond(202, { ok: true, sentCount: emails.length, sent, skipped, checkedAt: now.toISOString() })];
'@

$nodes = @(
    @{
        id = "checkpoint10b-tab"
        type = "tab"
        label = "Checkpoint 10B - Meeting Reminders"
        disabled = $false
        info = "Persistent scheduled meeting reminders that send once through Mailpit."
    },
    @{
        id = "checkpoint10b-comment"
        type = "comment"
        z = "checkpoint10b-tab"
        name = "GET/POST /api/meeting-reminders | DELETE /api/meeting-reminders/:id | POST /api/meeting-reminders/check"
        info = "The automatic checker runs every minute. Due reminders are marked sentAt to prevent repeat sends."
        x = 470
        y = 50
        wires = @()
    },
    @{
        id = "checkpoint10b-save-in"
        type = "http in"
        z = "checkpoint10b-tab"
        name = "Save meeting reminder"
        url = "/api/meeting-reminders"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 165
        y = 120
        wires = @(, @("checkpoint10b-save"))
    },
    @{
        id = "checkpoint10b-save"
        type = "function"
        z = "checkpoint10b-tab"
        name = "Validate and persist reminder"
        func = $saveCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 455
        y = 120
        wires = @(, @("checkpoint10b-save-response"))
    },
    @{
        id = "checkpoint10b-save-response"
        type = "http response"
        z = "checkpoint10b-tab"
        name = "Return saved reminder"
        statusCode = ""
        headers = @{}
        x = 760
        y = 120
        wires = @()
    },
    @{
        id = "checkpoint10b-list-in"
        type = "http in"
        z = "checkpoint10b-tab"
        name = "List meeting reminders"
        url = "/api/meeting-reminders"
        method = "get"
        upload = $false
        swaggerDoc = ""
        x = 170
        y = 190
        wires = @(, @("checkpoint10b-list"))
    },
    @{
        id = "checkpoint10b-list"
        type = "function"
        z = "checkpoint10b-tab"
        name = "Read persistent reminders"
        func = $listCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 455
        y = 190
        wires = @(, @("checkpoint10b-list-response"))
    },
    @{
        id = "checkpoint10b-list-response"
        type = "http response"
        z = "checkpoint10b-tab"
        name = "Return reminder list"
        statusCode = ""
        headers = @{}
        x = 755
        y = 190
        wires = @()
    },
    @{
        id = "checkpoint10b-delete-in"
        type = "http in"
        z = "checkpoint10b-tab"
        name = "Delete meeting reminder"
        url = "/api/meeting-reminders/:id"
        method = "delete"
        upload = $false
        swaggerDoc = ""
        x = 175
        y = 260
        wires = @(, @("checkpoint10b-delete"))
    },
    @{
        id = "checkpoint10b-delete"
        type = "function"
        z = "checkpoint10b-tab"
        name = "Delete persistent reminder"
        func = $deleteCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 460
        y = 260
        wires = @(, @("checkpoint10b-delete-response"))
    },
    @{
        id = "checkpoint10b-delete-response"
        type = "http response"
        z = "checkpoint10b-tab"
        name = "Return delete result"
        statusCode = ""
        headers = @{}
        x = 760
        y = 260
        wires = @()
    },
    @{
        id = "checkpoint10b-check-in"
        type = "http in"
        z = "checkpoint10b-tab"
        name = "Run meeting reminder check"
        url = "/api/meeting-reminders/check"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 185
        y = 350
        wires = @(, @("checkpoint10b-check"))
    },
    @{
        id = "checkpoint10b-schedule"
        type = "inject"
        z = "checkpoint10b-tab"
        name = "Automatic reminder check every minute"
        props = @(@{ p = "payload"; v = "{}"; vt = "json" })
        repeat = "60"
        crontab = ""
        once = $false
        onceDelay = 1
        topic = ""
        x = 205
        y = 420
        wires = @(, @("checkpoint10b-check"))
    },
    @{
        id = "checkpoint10b-check"
        type = "function"
        z = "checkpoint10b-tab"
        name = "Find due reminders and build emails"
        func = $checkCode
        outputs = 2
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 500
        y = 385
        wires = @(
            @("checkpoint10b-email"),
            @("checkpoint10b-check-response")
        )
    },
    @{
        id = "checkpoint10b-email"
        type = "e-mail"
        z = "checkpoint10b-tab"
        server = "parman-mailpit"
        port = "1025"
        authtype = "NONE"
        saslformat = $false
        token = "oauth2Response.access_token"
        secure = $false
        tls = $false
        name = ""
        dname = "Send meeting reminder to Mailpit"
        x = 805
        y = 360
        wires = @()
    },
    @{
        id = "checkpoint10b-check-response"
        type = "http response"
        z = "checkpoint10b-tab"
        name = "Return reminder check"
        statusCode = ""
        headers = @{}
        x = 805
        y = 420
        wires = @()
    }
)

$allFlows = @($flows) + $nodes
$json = $allFlows | ConvertTo-Json -Depth 50 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Checkpoint 10B meeting reminders deployed."
