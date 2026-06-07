$ErrorActionPreference = "Stop"

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$templatePath = Join-Path $scriptRoot "templates\meeting-invitation-fa.html"
$logoPath = Join-Path $scriptRoot "assets\parman-logo-email.png"
$htmlTemplate = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)
$htmlTemplateJson = $htmlTemplate | ConvertTo-Json -Compress
$logoBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($logoPath))

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object { $_.z -ne "checkpoint6a-tab" -and $_.id -ne "checkpoint6a-tab" })

$functionCode = @'
const input = msg.payload || {};

function fail(statusCode, errors) {
    const response = {
        ...msg,
        statusCode,
        headers: { 'content-type': 'application/json; charset=utf-8' },
        payload: { ok: false, errors }
    };
    return [null, response];
}

function isValidTimeZone(zone) {
    try {
        new Intl.DateTimeFormat('en', { timeZone: zone }).format();
        return true;
    } catch {
        return false;
    }
}

function zonedParts(date, zone) {
    return Object.fromEntries(
        new Intl.DateTimeFormat('en-CA', {
            timeZone: zone,
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hourCycle: 'h23'
        }).formatToParts(date)
            .filter(part => part.type !== 'literal')
            .map(part => [part.type, part.value])
    );
}

function localDateTimeToUtc(dateText, timeText, zone) {
    const [year, month, day] = dateText.split('-').map(Number);
    const [hour, minute] = timeText.split(':').map(Number);
    const target = Date.UTC(year, month - 1, day, hour, minute, 0);
    let guess = target;

    for (let i = 0; i < 4; i += 1) {
        const parts = zonedParts(new Date(guess), zone);
        const represented = Date.UTC(
            Number(parts.year),
            Number(parts.month) - 1,
            Number(parts.day),
            Number(parts.hour),
            Number(parts.minute),
            Number(parts.second)
        );
        guess += target - represented;
    }

    const result = new Date(guess);
    const check = zonedParts(result, zone);
    if (
        Number(check.year) !== year ||
        Number(check.month) !== month ||
        Number(check.day) !== day ||
        Number(check.hour) !== hour ||
        Number(check.minute) !== minute
    ) {
        throw new Error('The local date/time does not exist in that timezone, likely because of daylight saving.');
    }
    return result;
}

function escapeHtml(value) {
    return String(value)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
}

function escapeIcs(value) {
    return String(value)
        .replace(/\\/g, '\\\\')
        .replace(/\n/g, '\\n')
        .replace(/,/g, '\\,')
        .replace(/;/g, '\\;');
}

function icsDate(date) {
    return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z$/, 'Z');
}

const errors = [];
const requiredText = ['title', 'date', 'time', 'timezone', 'zoomUrl', 'meetingId', 'passcode'];
for (const field of requiredText) {
    if (typeof input[field] !== 'string' || !input[field].trim()) {
        errors.push(`${field} is required`);
    }
}
if (!/^\d{4}-\d{2}-\d{2}$/.test(input.date || '')) {
    errors.push('date must use YYYY-MM-DD');
}
if (!/^\d{2}:\d{2}$/.test(input.time || '')) {
    errors.push('time must use HH:mm');
}
if (!Number.isInteger(input.durationMinutes) || input.durationMinutes < 5 || input.durationMinutes > 1440) {
    errors.push('durationMinutes must be an integer between 5 and 1440');
}
if (!Array.isArray(input.agenda) || input.agenda.length === 0 || input.agenda.some(item => typeof item !== 'string' || !item.trim())) {
    errors.push('agenda must contain at least one non-empty item');
}
if (!Array.isArray(input.recipients) || input.recipients.length === 0 || input.recipients.some(item => typeof item !== 'string' || !item.includes('@'))) {
    errors.push('recipients must contain at least one email address');
}
if (!input.organizer || typeof input.organizer.name !== 'string' || typeof input.organizer.email !== 'string' || !input.organizer.email.includes('@')) {
    errors.push('organizer.name and organizer.email are required');
}
if (input.timezone && !isValidTimeZone(input.timezone)) {
    errors.push('timezone must be a valid IANA timezone such as Europe/Paris');
}

const defaultZones = [
    { label: 'اروپای مرکزی', timezone: 'Europe/Paris' },
    { label: 'ملبورن', timezone: 'Australia/Melbourne' },
    { label: 'لندن', timezone: 'Europe/London' },
    { label: 'نیویورک', timezone: 'America/New_York' }
];
const displayTimezones = input.displayTimezones || defaultZones;
if (
    !Array.isArray(displayTimezones) ||
    displayTimezones.length === 0 ||
    displayTimezones.some(item => !item || typeof item.label !== 'string' || !isValidTimeZone(item.timezone))
) {
    errors.push('displayTimezones must contain valid label and IANA timezone values');
}

if (errors.length) {
    return fail(400, errors);
}

let startUtc;
try {
    startUtc = localDateTimeToUtc(input.date, input.time, input.timezone);
} catch (error) {
    return fail(400, [error.message]);
}
const endUtc = new Date(startUtc.getTime() + input.durationMinutes * 60000);

const locale = 'fa-IR-u-ca-gregory';
const formatLocal = (date, zone) => new Intl.DateTimeFormat(locale, {
    timeZone: zone,
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
    timeZoneName: 'short'
}).format(date);
const sourceDate = new Intl.DateTimeFormat(locale, {
    timeZone: input.timezone,
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric'
}).format(startUtc);
const sourceTime = new Intl.DateTimeFormat(locale, {
    timeZone: input.timezone,
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
    timeZoneName: 'short'
}).format(startUtc);

const timezoneRows = displayTimezones.map(item =>
    `<tr>` +
    `<td class="time-cell" style="padding:12px 16px;border-bottom:1px solid #dce7ee;font-weight:700;color:#173b57;width:34%">${escapeHtml(item.label)}</td>` +
    `<td class="time-cell" dir="rtl" style="padding:12px 16px;border-bottom:1px solid #dce7ee">${escapeHtml(formatLocal(startUtc, item.timezone))}</td>` +
    `</tr>`
).join('');
const agendaRows = input.agenda.map((item, index) =>
    `<tr><td style="padding:10px 0;vertical-align:top;border-bottom:1px solid #edf1f4">` +
    `<span style="display:inline-block;width:30px;height:30px;margin-left:10px;border-radius:50%;background:#e7f2f8;color:#173b57;text-align:center;line-height:30px;font-weight:800">${index + 1}</span>` +
    `${escapeHtml(item)}</td></tr>`
).join('');

const htmlTemplate = __HTML_TEMPLATE_JSON__;
const subject = `دعوت‌نامه: ${input.title}`;
const greeting = input.greeting || 'دوستان گرامی';
const closing = (input.closing || 'پاینده ایران\nجاوید شاه').split('\n').map(escapeHtml).join('<br>');
const html = htmlTemplate
    .replaceAll('{{SUBJECT}}', escapeHtml(subject))
    .replace('{{PREHEADER}}', escapeHtml(`${input.title}، ${sourceDate}، ${sourceTime}`))
    .replaceAll('{{MEETING_TITLE}}', escapeHtml(input.title))
    .replace('{{GREETING}}', escapeHtml(greeting))
    .replaceAll('{{SOURCE_DATE}}', escapeHtml(sourceDate))
    .replace('{{SOURCE_TIME}}', escapeHtml(sourceTime))
    .replace('{{DURATION_MINUTES}}', String(input.durationMinutes))
    .replace('{{AGENDA_ROWS}}', agendaRows)
    .replace('{{TIMEZONE_ROWS}}', timezoneRows)
    .replaceAll('{{ZOOM_URL}}', escapeHtml(input.zoomUrl))
    .replace('{{MEETING_ID}}', escapeHtml(input.meetingId))
    .replace('{{PASSCODE}}', escapeHtml(input.passcode))
    .replace('{{CLOSING}}', closing)
    .replace('{{ORGANIZER_NAME}}', escapeHtml(input.organizer.name));

const description = [
    ...input.agenda.map((item, index) => `${index + 1}. ${item}`),
    '',
    `Zoom: ${input.zoomUrl}`,
    `Meeting ID: ${input.meetingId}`,
    `Passcode: ${input.passcode}`
].join('\n');
const uid = `${Date.now()}-${Math.random().toString(16).slice(2)}@parman.local`;
const ics = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Parman//Node-RED Dynamic Meeting API//FA',
    'CALSCALE:GREGORIAN',
    'METHOD:REQUEST',
    'BEGIN:VEVENT',
    `UID:${uid}`,
    `DTSTAMP:${icsDate(new Date())}`,
    `DTSTART:${icsDate(startUtc)}`,
    `DTEND:${icsDate(endUtc)}`,
    `SUMMARY:${escapeIcs(input.title)}`,
    `DESCRIPTION:${escapeIcs(description)}`,
    `LOCATION:${escapeIcs(input.zoomUrl)}`,
    `URL:${input.zoomUrl}`,
    `ORGANIZER;CN=${escapeIcs(input.organizer.name)}:mailto:${input.organizer.email}`,
    ...input.recipients.map(address => `ATTENDEE;ROLE=REQ-PARTICIPANT;RSVP=TRUE:mailto:${address}`),
    'STATUS:CONFIRMED',
    'SEQUENCE:0',
    'END:VEVENT',
    'END:VCALENDAR'
].join('\r\n');

const emailMessage = {
    ...msg,
    to: input.recipients.join(','),
    from: input.organizer.email,
    topic: subject,
    payload: html,
    attachments: [
        {
            filename: 'parman-logo.png',
            content: Buffer.from('__LOGO_BASE64__', 'base64'),
            contentType: 'image/png',
            cid: 'parman-logo'
        },
        {
            filename: 'meeting-invite.ics',
            content: ics,
            contentType: 'text/calendar; method=REQUEST; charset=UTF-8'
        }
    ]
};
delete emailMessage.req;
delete emailMessage.res;

const response = {
    ...msg,
    statusCode: 202,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    payload: {
        ok: true,
        message: 'Meeting invitation accepted for delivery',
        meeting: {
            title: input.title,
            sourceDateTime: `${input.date}T${input.time}`,
            sourceTimezone: input.timezone,
            startUtc: startUtc.toISOString(),
            endUtc: endUtc.toISOString(),
            recipients: input.recipients,
            displayedTimezones: displayTimezones
        }
    }
};

return [emailMessage, response];
'@
$functionCode = $functionCode.Replace("__HTML_TEMPLATE_JSON__", $htmlTemplateJson)
$functionCode = $functionCode.Replace("__LOGO_BASE64__", $logoBase64)

$apiNodes = @(
    @{
        id = "checkpoint6a-tab"
        type = "tab"
        label = "Checkpoint 6A - Dynamic Meeting API"
        disabled = $false
        info = "POST dynamic meeting data to /api/meetings/send."
    },
    @{
        id = "checkpoint6a-comment"
        type = "comment"
        z = "checkpoint6a-tab"
        name = "POST /api/meetings/send - validates, converts timezone, creates HTML + ICS, sends email"
        info = "Content-Type: application/json"
        x = 420
        y = 60
        wires = @()
    },
    @{
        id = "checkpoint6a-http-in"
        type = "http in"
        z = "checkpoint6a-tab"
        name = "Dynamic meeting API"
        url = "/api/meetings/send"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 150
        y = 140
        wires = @(, @("checkpoint6a-build"))
    },
    @{
        id = "checkpoint6a-build"
        type = "function"
        z = "checkpoint6a-tab"
        name = "Validate and build invitation"
        func = $functionCode
        outputs = 2
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 420
        y = 140
        wires = @(
            @("checkpoint6a-email"),
            @("checkpoint6a-response")
        )
    },
    @{
        id = "checkpoint6a-email"
        type = "e-mail"
        z = "checkpoint6a-tab"
        server = "parman-mailpit"
        port = "1025"
        authtype = "NONE"
        saslformat = $false
        token = "oauth2Response.access_token"
        secure = $false
        tls = $false
        name = ""
        dname = "Send dynamic invite to Mailpit"
        x = 730
        y = 110
        wires = @()
    },
    @{
        id = "checkpoint6a-response"
        type = "http response"
        z = "checkpoint6a-tab"
        name = "Return API result"
        statusCode = ""
        headers = @{}
        x = 720
        y = 180
        wires = @()
    }
)

$allFlows = @($flows) + $apiNodes
$json = $allFlows | ConvertTo-Json -Depth 40 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Dynamic meeting API deployed."
