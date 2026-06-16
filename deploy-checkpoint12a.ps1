$ErrorActionPreference = "Stop"

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object {
    $_.id -notmatch "^checkpoint12a-" -and
    $_.z -ne "checkpoint12a-tab"
})

$getCode = @'
const saved = global.get('appSettings') || {};
const tg = saved.telegram || {};
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = {
    ok: true,
    telegram: {
        botTokenConfigured: Boolean(tg.botToken),
        defaultChatId: tg.defaultChatId || ''
    }
};
return msg;
'@

$postCode = @'
const body = msg.payload || {};
const errors = [];
const botToken = String(body.botToken || '').trim();
const defaultChatId = String(body.defaultChatId || '').trim();
if (!botToken) {
    errors.push('botToken is required');
} else if (!/^\d+:[A-Za-z0-9_-]{35,}$/.test(botToken)) {
    errors.push('botToken does not look like a valid Telegram bot token (format: 123456789:ABCdefGHI...)');
}
if (!defaultChatId) {
    errors.push('defaultChatId is required');
}
if (errors.length) {
    msg.statusCode = 400;
    msg.headers = { 'content-type': 'application/json; charset=utf-8' };
    msg.payload = { ok: false, errors };
    return msg;
}
const current = global.get('appSettings') || {};
current.telegram = { botToken, defaultChatId, savedAt: new Date().toISOString() };
global.set('appSettings', current);
msg.statusCode = 200;
msg.headers = { 'content-type': 'application/json; charset=utf-8' };
msg.payload = { ok: true, message: 'Telegram settings saved.' };
return msg;
'@

$nodes = @(
    @{
        id = "checkpoint12a-tab"
        type = "tab"
        label = "Checkpoint 12A - Telegram"
        disabled = $false
        info = "Telegram bot token and default chat ID settings. GET never returns the token."
    },
    @{
        id = "checkpoint12a-comment"
        type = "comment"
        z = "checkpoint12a-tab"
        name = "GET /api/settings/telegram | POST /api/settings/telegram"
        info = "Stores the Telegram bot token and default chat ID in appSettings. The token is never returned in GET responses."
        x = 410
        y = 55
        wires = @()
    },
    @{
        id = "checkpoint12a-get-in"
        type = "http in"
        z = "checkpoint12a-tab"
        name = "Get Telegram settings"
        url = "/api/settings/telegram"
        method = "get"
        upload = $false
        swaggerDoc = ""
        x = 155
        y = 130
        wires = @(, @("checkpoint12a-get"))
    },
    @{
        id = "checkpoint12a-get"
        type = "function"
        z = "checkpoint12a-tab"
        name = "Read Telegram settings"
        func = $getCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 420
        y = 130
        wires = @(, @("checkpoint12a-get-response"))
    },
    @{
        id = "checkpoint12a-get-response"
        type = "http response"
        z = "checkpoint12a-tab"
        name = "Return Telegram settings"
        statusCode = ""
        headers = @{}
        x = 705
        y = 130
        wires = @()
    },
    @{
        id = "checkpoint12a-post-in"
        type = "http in"
        z = "checkpoint12a-tab"
        name = "Save Telegram settings"
        url = "/api/settings/telegram"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 160
        y = 205
        wires = @(, @("checkpoint12a-post"))
    },
    @{
        id = "checkpoint12a-post"
        type = "function"
        z = "checkpoint12a-tab"
        name = "Validate and save Telegram settings"
        func = $postCode
        outputs = 1
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 450
        y = 205
        wires = @(, @("checkpoint12a-post-response"))
    },
    @{
        id = "checkpoint12a-post-response"
        type = "http response"
        z = "checkpoint12a-tab"
        name = "Return save result"
        statusCode = ""
        headers = @{}
        x = 745
        y = 205
        wires = @()
    }
)

$allFlows = @($flows) + $nodes
$json = $allFlows | ConvertTo-Json -Depth 50 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Checkpoint 12A Telegram settings deployed."
