$ErrorActionPreference = "Stop"

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$templatePath = Join-Path $scriptRoot "templates\birthday-congratulations-fa.html"
$logoPath = Join-Path $scriptRoot "assets\parman-logo-email.png"
$htmlTemplate = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)
$htmlTemplateJson = $htmlTemplate | ConvertTo-Json -Compress
$logoBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($logoPath))

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object { $_.z -ne "checkpoint6b-tab" -and $_.id -ne "checkpoint6b-tab" })

$saveCode = @'
const input = msg.payload || {};
const errors = [];

function validTimezone(zone) {
    try {
        new Intl.DateTimeFormat('en', { timeZone: zone }).format();
        return true;
    } catch {
        return false;
    }
}

if (typeof input.name !== 'string' || !input.name.trim()) {
    errors.push('name is required');
}
if (!/^(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/.test(input.birthday || '')) {
    errors.push('birthday must use MM-DD');
}
if (typeof input.timezone !== 'string' || !validTimezone(input.timezone)) {
    errors.push('timezone must be a valid IANA timezone such as Australia/Melbourne');
}
if (!Number.isInteger(input.sendHour) || input.sendHour < 0 || input.sendHour > 23) {
    errors.push('sendHour must be an integer from 0 to 23');
}
if (
    !Array.isArray(input.recipientEmails) ||
    input.recipientEmails.length === 0 ||
    input.recipientEmails.some(address => typeof address !== 'string' || !address.includes('@'))
) {
    errors.push('recipientEmails must contain at least one email address');
}

if (errors.length) {
    msg.statusCode = 400;
    msg.headers = { 'content-type': 'application/json; charset=utf-8' };
    msg.payload = { ok: false, errors };
    return msg;
}

const contacts = global.get('birthdayContacts') || [];
const id = typeof input.id === 'string' && input.id.trim()
    ? input.id.trim()
    : `${Date.now()}-${Math.random().toString(16).slice(2)}`;
const contact = {
    id,
    name: input.name.trim(),
    birthday: input.birthday,
    timezone: input.timezone,
    sendHour: input.sendHour,
    recipientEmails: [...new Set(input.recipientEmails.map(value => value.trim().toLowerCase()))],
    active: input.active !== false,
    updatedAt: new Date().toISOString()
};
const index = contacts.findIndex(item => item.id === id);
const created = index === -1;
if (created) {
    contacts.push(contact);
} else {
    contacts[index] = contact;
}
global.set('birthdayContacts', contacts);

msg.statusCode = created ? 201 : 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = { ok: true, created, contact };
return msg;
'@

$listCode = @'
const contacts = global.get('birthdayContacts') || [];
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = {
    ok: true,
    count: contacts.length,
    contacts: contacts.slice().sort((a, b) => a.name.localeCompare(b.name, 'fa'))
};
return msg;
'@

$checkCode = @'
const options = msg.payload && typeof msg.payload === 'object' ? msg.payload : {};
const isHttp = Boolean(msg.req && msg.res);
const contacts = (global.get('birthdayContacts') || []).filter(contact => contact.active !== false);
const sent = global.get('birthdayDeliveries') || {};
const now = options.now ? new Date(options.now) : new Date();
const force = options.force === true;
const selectedIds = Array.isArray(options.contactIds) ? new Set(options.contactIds) : null;

function respond(statusCode, payload) {
    if (!isHttp) {
        return null;
    }
    return {
        ...msg,
        statusCode,
        headers: { 'content-type': 'application/json; charset=utf-8' },
        payload
    };
}

function escapeHtml(value) {
    return String(value)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
}

function localParts(date, zone) {
    return Object.fromEntries(
        new Intl.DateTimeFormat('en-CA', {
            timeZone: zone,
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            hourCycle: 'h23'
        }).formatToParts(date)
            .filter(part => part.type !== 'literal')
            .map(part => [part.type, part.value])
    );
}

if (Number.isNaN(now.getTime())) {
    return [null, respond(400, { ok: false, errors: ['now must be a valid ISO date/time'] })];
}
if (contacts.length === 0) {
    return [null, respond(200, { ok: true, queued: 0, skipped: 0, message: 'No active birthday contacts saved' })];
}

const due = [];
const skipped = [];
for (const contact of contacts) {
    if (selectedIds && !selectedIds.has(contact.id)) {
        continue;
    }
    const parts = localParts(now, contact.timezone);
    const localBirthday = `${parts.month}-${parts.day}`;
    const inWindow =
        localBirthday === contact.birthday &&
        Number(parts.hour) === contact.sendHour &&
        Number(parts.minute) < 15;
    const deliveryKey = `birthday:${contact.id}:${parts.year}`;

    if (!force && !inWindow) {
        skipped.push({ id: contact.id, name: contact.name, reason: 'not due', localDateTime: `${parts.year}-${localBirthday} ${parts.hour}:${parts.minute}` });
        continue;
    }
    if (!force && sent[deliveryKey]) {
        skipped.push({ id: contact.id, name: contact.name, reason: 'already sent', sentAt: sent[deliveryKey] });
        continue;
    }
    due.push({ contact, parts, deliveryKey });
}

const groups = new Map();
for (const item of due) {
    const recipients = item.contact.recipientEmails.slice().sort();
    const groupKey = recipients.join(',');
    if (!groups.has(groupKey)) {
        groups.set(groupKey, { recipients, items: [] });
    }
    groups.get(groupKey).items.push(item);
}

const htmlTemplate = __HTML_TEMPLATE_JSON__;
const emails = [];
const queuedContacts = [];
for (const group of groups.values()) {
    const names = group.items.map(item => item.contact.name);
    const namesBlock = names.map(name => `<div>${escapeHtml(name)}</div>`).join('');
    const namesInline = names.map(name => `<strong>${escapeHtml(name)}</strong>`).join(' و ');
    const subjectNames = names.join(' و ');
    const subject = `شادباش زادروز ${subjectNames}`;
    const html = htmlTemplate
        .replaceAll('{{SUBJECT}}', escapeHtml(subject))
        .replace('{{HONOREE_NAMES}}', namesBlock)
        .replace('{{HONOREE_NAMES_INLINE}}', namesInline);

    emails.push({
        to: group.recipients.join(','),
        from: options.from || 'public-relations@parman.local',
        topic: subject,
        payload: html,
        attachments: [{
            filename: 'parman-logo.png',
            content: Buffer.from('__LOGO_BASE64__', 'base64'),
            contentType: 'image/png',
            cid: 'parman-logo'
        }]
    });

    for (const item of group.items) {
        queuedContacts.push({
            id: item.contact.id,
            name: item.contact.name,
            recipients: group.recipients,
            timezone: item.contact.timezone
        });
        if (!force) {
            sent[item.deliveryKey] = now.toISOString();
        }
    }
}

if (!force) {
    global.set('birthdayDeliveries', sent);
}

const response = respond(202, {
    ok: true,
    queued: emails.length,
    queuedContacts,
    skipped,
    force,
    checkedAt: now.toISOString()
});
return [emails.length ? emails : null, response];
'@
$checkCode = $checkCode.Replace("__HTML_TEMPLATE_JSON__", $htmlTemplateJson)
$checkCode = $checkCode.Replace("__LOGO_BASE64__", $logoBase64)

$nodes = @(
    @{
        id = "checkpoint6b-tab"
        type = "tab"
        label = "Checkpoint 6B - Dynamic Birthdays"
        disabled = $false
        info = "Persistent birthday contacts, timezone-aware checks, branded email delivery."
    },
    @{
        id = "checkpoint6b-comment"
        type = "comment"
        z = "checkpoint6b-tab"
        name = "Save/list contacts and run birthday checks. Data survives Node-RED restarts."
        info = "POST /api/birthdays/contacts, GET /api/birthdays/contacts, POST /api/birthdays/check"
        x = 400
        y = 50
        wires = @()
    },
    @{
        id = "checkpoint6b-save-in"
        type = "http in"
        z = "checkpoint6b-tab"
        name = "Save birthday contact"
        url = "/api/birthdays/contacts"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 150
        y = 120
        wires = @(, @("checkpoint6b-save"))
    },
    @{
        id = "checkpoint6b-save"
        type = "function"
        z = "checkpoint6b-tab"
        name = "Validate and persist contact"
        func = $saveCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 430
        y = 120
        wires = @(, @("checkpoint6b-save-response"))
    },
    @{
        id = "checkpoint6b-save-response"
        type = "http response"
        z = "checkpoint6b-tab"
        name = "Return saved contact"
        statusCode = ""
        headers = @{}
        x = 720
        y = 120
        wires = @()
    },
    @{
        id = "checkpoint6b-list-in"
        type = "http in"
        z = "checkpoint6b-tab"
        name = "List birthday contacts"
        url = "/api/birthdays/contacts"
        method = "get"
        upload = $false
        swaggerDoc = ""
        x = 150
        y = 190
        wires = @(, @("checkpoint6b-list"))
    },
    @{
        id = "checkpoint6b-list"
        type = "function"
        z = "checkpoint6b-tab"
        name = "Read persistent contacts"
        func = $listCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 420
        y = 190
        wires = @(, @("checkpoint6b-list-response"))
    },
    @{
        id = "checkpoint6b-list-response"
        type = "http response"
        z = "checkpoint6b-tab"
        name = "Return contact list"
        statusCode = ""
        headers = @{}
        x = 710
        y = 190
        wires = @()
    },
    @{
        id = "checkpoint6b-check-in"
        type = "http in"
        z = "checkpoint6b-tab"
        name = "Run birthday check"
        url = "/api/birthdays/check"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 140
        y = 290
        wires = @(, @("checkpoint6b-check"))
    },
    @{
        id = "checkpoint6b-schedule"
        type = "inject"
        z = "checkpoint6b-tab"
        name = "Automatic check every 15 minutes"
        props = @(@{ p = "payload"; v = "{}"; vt = "json" })
        repeat = "900"
        crontab = ""
        once = $false
        onceDelay = 1
        topic = ""
        x = 170
        y = 360
        wires = @(, @("checkpoint6b-check"))
    },
    @{
        id = "checkpoint6b-check"
        type = "function"
        z = "checkpoint6b-tab"
        name = "Find due birthdays and build emails"
        func = $checkCode
        outputs = 2
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 450
        y = 320
        wires = @(
            @("checkpoint6b-email"),
            @("checkpoint6b-check-response")
        )
    },
    @{
        id = "checkpoint6b-email"
        type = "e-mail"
        z = "checkpoint6b-tab"
        server = "parman-mailpit"
        port = "1025"
        authtype = "NONE"
        saslformat = $false
        token = "oauth2Response.access_token"
        secure = $false
        tls = $false
        name = ""
        dname = "Send dynamic birthday email"
        x = 760
        y = 290
        wires = @()
    },
    @{
        id = "checkpoint6b-check-response"
        type = "http response"
        z = "checkpoint6b-tab"
        name = "Return check result"
        statusCode = ""
        headers = @{}
        x = 740
        y = 350
        wires = @()
    }
)

$allFlows = @($flows) + $nodes
$json = $allFlows | ConvertTo-Json -Depth 40 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Dynamic birthday APIs deployed."
