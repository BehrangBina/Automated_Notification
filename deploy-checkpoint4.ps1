$ErrorActionPreference = "Stop"

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$templatePath = Join-Path $scriptRoot "templates\birthday-congratulations-fa.html"
$logoPath = Join-Path $scriptRoot "assets\parman-logo-email.png"
$htmlTemplate = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)
$htmlTemplateJson = $htmlTemplate | ConvertTo-Json -Compress
$logoBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($logoPath))

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json

$functionNode = $flows | Where-Object id -eq "checkpoint4-function"
$functionNode.func = @'
const people = [
    {
        id: 'parvin-zandi',
        name: 'بانو پروین زندی گرامی',
        email: 'demo@parman.local',
        birthday: '06-07',
        timezone: 'Australia/Sydney',
        sendHour: 9
    },
    {
        id: 'mona-afshar',
        name: 'بانو مونا افشار گرامی',
        email: 'demo@parman.local',
        birthday: '06-07',
        timezone: 'Australia/Sydney',
        sendHour: 9
    }
];

const now = new Date();
const person = people[0];
const parts = Object.fromEntries(
    new Intl.DateTimeFormat('en-CA', {
        timeZone: person.timezone,
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        hourCycle: 'h23'
    }).formatToParts(now)
        .filter(part => part.type !== 'literal')
        .map(part => [part.type, part.value])
);

const localBirthday = `${parts.month}-${parts.day}`;
const scheduledWindow = people.some(item =>
    item.birthday === localBirthday &&
    Number(parts.hour) === item.sendHour &&
    Number(parts.minute) < 15
);

if (!msg.forceTest && !scheduledWindow) {
    node.status({
        fill: 'grey',
        shape: 'ring',
        text: `No birthday due: ${parts.year}-${localBirthday} ${parts.hour}:${parts.minute}`
    });
    return null;
}

const deliveryKey = `birthday-group:${parts.year}:${localBirthday}`;
const sent = flow.get('birthdaySent') || {};
if (!msg.forceTest && sent[deliveryKey]) {
    node.status({ fill: 'blue', shape: 'ring', text: 'Already sent today' });
    return null;
}

sent[deliveryKey] = now.toISOString();
flow.set('birthdaySent', sent);

const htmlTemplate = __HTML_TEMPLATE_JSON__;
const namesBlock = people.map(item => `<div>${item.name}</div>`).join('');
const namesInline = people.map(item => `<strong>${item.name}</strong>`).join(' و ');

msg.from = 'public-relations@parman.local';
msg.topic = 'شادباش زادروز بانو پروین زندی و بانو مونا افشار';
msg.payload = htmlTemplate
    .replaceAll('{{SUBJECT}}', msg.topic)
    .replace('{{HONOREE_NAMES}}', namesBlock)
    .replace('{{HONOREE_NAMES_INLINE}}', namesInline);
msg.attachments = [{
    filename: 'parman-logo.png',
    content: Buffer.from('__LOGO_BASE64__', 'base64'),
    contentType: 'image/png',
    cid: 'parman-logo'
}];

node.status({ fill: 'green', shape: 'dot', text: 'Branded birthday email prepared' });
return msg;
'@
$functionNode.func = $functionNode.func.Replace("__HTML_TEMPLATE_JSON__", $htmlTemplateJson)
$functionNode.func = $functionNode.func.Replace("__LOGO_BASE64__", $logoBase64)

$testNode = $flows | Where-Object id -eq "checkpoint4-test"
$testNode.once = $true

$json = $flows | ConvertTo-Json -Depth 30 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Start-Sleep -Seconds 4

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
($flows | Where-Object id -eq "checkpoint4-test").once = $false

$json = $flows | ConvertTo-Json -Depth 30 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Branded birthday invitation deployed and sent."
