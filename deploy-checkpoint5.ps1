$ErrorActionPreference = "Stop"

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$templatePath = Join-Path $scriptRoot "templates\meeting-invitation-fa.html"
$htmlTemplate = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)
$htmlTemplateJson = $htmlTemplate | ConvertTo-Json -Compress
$logoPath = Join-Path $scriptRoot "assets\parman-logo-email.png"
$logoBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($logoPath))

$functionNode = $flows | Where-Object id -eq "checkpoint5-function"
$functionNode.func = @'
const meeting = {
    uid: 'parman-software-working-group-20260607@example.local',
    title: 'جلسه کارگروه نرم‌افزار پارمان',
    startUtc: new Date('2026-06-07T09:00:00Z'),
    endUtc: new Date('2026-06-07T10:00:00Z'),
    organizerName: 'مینا چنگیزی',
    organizer: 'mina@parman.local',
    attendee: 'demo@parman.local',
    zoomUrl: 'https://us02web.zoom.us/j/5664080599?pwd=Thi0sLCW7G0hybX5fh7boMKinhi1At.1v',
    meetingId: '566 408 0599',
    passcode: 'abv'
};

const zones = [
    ['اروپای مرکزی', 'Europe/Paris'],
    ['ملبورن', 'Australia/Melbourne'],
    ['لندن', 'Europe/London'],
    ['نیویورک', 'America/New_York']
];

function localTime(date, zone) {
    return new Intl.DateTimeFormat('fa-IR', {
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
}

function icsDate(date) {
    return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z$/, 'Z');
}

function escapeIcs(value) {
    return value
        .replace(/\\/g, '\\\\')
        .replace(/\n/g, '\\n')
        .replace(/,/g, '\\,')
        .replace(/;/g, '\\;');
}

const rows = zones.map(([city, zone]) =>
    `<tr>` +
    `<td class="time-cell" style="padding:12px 16px;border-bottom:1px solid #dce7ee;font-weight:700;color:#173b57;width:34%">${city}</td>` +
    `<td class="time-cell" dir="rtl" style="padding:12px 16px;border-bottom:1px solid #dce7ee">${localTime(meeting.startUtc, zone)}</td>` +
    `</tr>`
).join('');

const agenda = [
    '۱. خوشامدگویی و معرفی جناب بینا',
    '۲. اولویت‌بندی نیازهای پارمان که نیاز به اتوماسیون دارند',
    '۳. ارائه جناب آقای انصاری درباره اتوماسیون بخشی از فرایند عضویت به اعضای شورای مدیریت'
];
const agendaText = agenda.join('\n');
const agendaRows = agenda.map((item, index) =>
    `<tr><td style="padding:10px 0;vertical-align:top;border-bottom:1px solid #edf1f4">` +
    `<span style="display:inline-block;width:30px;height:30px;margin-left:10px;border-radius:50%;background:#e7f2f8;color:#173b57;text-align:center;line-height:30px;font-weight:800">${index + 1}</span>` +
    `${item.replace(/^[۰-۹]+\.\s*/, '')}</td></tr>`
).join('');

const description = `${agendaText}

Zoom: ${meeting.zoomUrl}
Meeting ID: ${meeting.meetingId}
Passcode: ${meeting.passcode}`;

const ics = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Parman//Node-RED POC//FA',
    'CALSCALE:GREGORIAN',
    'METHOD:REQUEST',
    'BEGIN:VEVENT',
    `UID:${meeting.uid}`,
    `DTSTAMP:${icsDate(new Date())}`,
    `DTSTART:${icsDate(meeting.startUtc)}`,
    `DTEND:${icsDate(meeting.endUtc)}`,
    `SUMMARY:${escapeIcs(meeting.title)}`,
    `DESCRIPTION:${escapeIcs(description)}`,
    `LOCATION:${escapeIcs(meeting.zoomUrl)}`,
    `URL:${meeting.zoomUrl}`,
    `ORGANIZER;CN=${escapeIcs(meeting.organizerName)}:mailto:${meeting.organizer}`,
    `ATTENDEE;ROLE=REQ-PARTICIPANT;RSVP=TRUE:mailto:${meeting.attendee}`,
    'STATUS:CONFIRMED',
    'SEQUENCE:0',
    'END:VEVENT',
    'END:VCALENDAR'
].join('\r\n');

msg.from = meeting.organizer;
msg.topic = 'دعوت‌نامه جلسه کارگروه نرم‌افزار پارمان';
const htmlTemplate = __HTML_TEMPLATE_JSON__;
msg.payload = htmlTemplate
    .replaceAll('{{SUBJECT}}', msg.topic)
    .replace('{{AGENDA_ROWS}}', agendaRows)
    .replace('{{TIMEZONE_ROWS}}', rows)
    .replaceAll('{{ZOOM_URL}}', meeting.zoomUrl)
    .replace('{{MEETING_ID}}', meeting.meetingId)
    .replace('{{PASSCODE}}', meeting.passcode)
    .replace('{{ORGANIZER_NAME}}', meeting.organizerName);

msg.attachments = [
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
];

node.status({ fill: 'green', shape: 'dot', text: 'Persian invite prepared' });
return msg;
'@
$functionNode.func = $functionNode.func.Replace("__HTML_TEMPLATE_JSON__", $htmlTemplateJson)
$functionNode.func = $functionNode.func.Replace("__LOGO_BASE64__", $logoBase64)

$testNode = $flows | Where-Object id -eq "checkpoint5-test"
$testNode.once = $true

$json = $flows | ConvertTo-Json -Depth 30 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Start-Sleep -Seconds 4

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
($flows | Where-Object id -eq "checkpoint5-test").once = $false

$json = $flows | ConvertTo-Json -Depth 30 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Persian meeting invitation deployed and sent."
