$ErrorActionPreference = "Stop"

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$templatePath = Join-Path $scriptRoot "templates\notification.html"
$logoPath = Join-Path $scriptRoot "assets\parman-logo-email.png"
$htmlTemplate = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)
$htmlTemplateJson = $htmlTemplate | ConvertTo-Json -Compress
$logoBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($logoPath))

$flows = (Invoke-WebRequest -UseBasicParsing http://localhost:1880/flows).Content |
    ConvertFrom-Json
$flows = @($flows | Where-Object { $_.z -ne "checkpoint6c-tab" -and $_.id -ne "checkpoint6c-tab" })

$functionCode = @'
const input = msg.payload || {};
const errors = [];

function escapeHtml(value) {
    return String(value)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
}

if (!['fa', 'en'].includes(input.language)) {
    errors.push('language must be fa or en');
}
if (typeof input.subject !== 'string' || !input.subject.trim()) {
    errors.push('subject is required');
}
if (typeof input.title !== 'string' || !input.title.trim()) {
    errors.push('title is required');
}
if (
    !(typeof input.message === 'string' && input.message.trim()) &&
    !(Array.isArray(input.paragraphs) && input.paragraphs.length && input.paragraphs.every(item => typeof item === 'string' && item.trim()))
) {
    errors.push('provide message or a non-empty paragraphs array');
}
if (
    !Array.isArray(input.recipients) ||
    input.recipients.length === 0 ||
    input.recipients.some(address => typeof address !== 'string' || !address.includes('@'))
) {
    errors.push('recipients must contain at least one email address');
}
if (input.type !== undefined && !['info', 'success', 'warning', 'urgent'].includes(input.type)) {
    errors.push('type must be info, success, warning, or urgent');
}
if (
    input.action !== undefined &&
    (
        !input.action ||
        typeof input.action.label !== 'string' ||
        !input.action.label.trim() ||
        typeof input.action.url !== 'string' ||
        !/^https?:\/\//i.test(input.action.url)
    )
) {
    errors.push('action requires a label and an http/https URL');
}
if (
    input.channels !== undefined &&
    (
        !Array.isArray(input.channels) ||
        input.channels.length === 0 ||
        input.channels.some(function(ch) { return ch !== 'email' && ch !== 'telegram'; })
    )
) {
    errors.push('channels must be an array containing email and/or telegram');
}

if (errors.length) {
    msg.statusCode = 400;
    msg.headers = { 'content-type': 'application/json; charset=utf-8' };
    msg.payload = { ok: false, errors };
    return [null, msg];
}

const language = input.language;
const rtl = language === 'fa';
const type = input.type || 'info';
const styles = {
    info: { accent: '#1473e6', background: '#edf5ff' },
    success: { accent: '#198754', background: '#edf8f2' },
    warning: { accent: '#c88a14', background: '#fff7e6' },
    urgent: { accent: '#c83b3b', background: '#fff0f0' }
};
const labels = {
    fa: {
        info: '\u0627\u0637\u0644\u0627\u0639\u06CC\u0647',
        success: '\u062E\u0628\u0631 \u0648 \u0628\u0647\u200C\u0631\u0648\u0632\u0631\u0633\u0627\u0646\u06CC',
        warning: '\u06CC\u0627\u062F\u0622\u0648\u0631\u06CC \u0645\u0647\u0645',
        urgent: '\u0627\u0637\u0644\u0627\u0639\u06CC\u0647 \u0641\u0648\u0631\u06CC',
        organization: '\u0631\u0648\u0627\u0628\u0637 \u0639\u0645\u0648\u0645\u06CC \u067E\u0627\u0631\u0645\u0627\u0646 \u067E\u0627\u062F\u0634\u0627\u0647\u06CC \u0627\u06CC\u0631\u0627\u0646\u06CC\u0627\u0646',
        footer: '\u0627\u06CC\u0646 \u067E\u06CC\u0627\u0645 \u0628\u0647\u200C\u0635\u0648\u0631\u062A \u062E\u0648\u062F\u06A9\u0627\u0631 \u062A\u0648\u0633\u0637 \u0633\u0627\u0645\u0627\u0646\u0647 \u0627\u062A\u0648\u0645\u0627\u0633\u06CC\u0648\u0646 \u067E\u0627\u0631\u0645\u0627\u0646 \u0627\u0631\u0633\u0627\u0644 \u0634\u062F\u0647 \u0627\u0633\u062A.'
    },
    en: {
        info: 'Information',
        success: 'Update',
        warning: 'Important reminder',
        urgent: 'Urgent notice',
        organization: 'Parman Public Relations',
        footer: 'This message was sent automatically by the Parman automation system.'
    }
};

const paragraphs = Array.isArray(input.paragraphs)
    ? input.paragraphs
    : input.message.split(/\r?\n\r?\n/);
const messageHtml = paragraphs
    .filter(value => value.trim())
    .map(value => `<p style="margin:0 0 17px;">${escapeHtml(value.trim()).replace(/\r?\n/g, '<br>')}</p>`)
    .join('');
const actionBlock = input.action
    ? `<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%;margin-top:28px;border-collapse:collapse;"><tr><td align="center"><a class="action-button" href="${escapeHtml(input.action.url)}" style="display:inline-block;background:${styles[type].accent};color:#ffffff;text-decoration:none;font-weight:800;font-size:16px;line-height:1;padding:16px 28px;border-radius:9px;">${escapeHtml(input.action.label)}</a></td></tr></table>`
    : '';

const template = __HTML_TEMPLATE_JSON__;
const html = template
    .replace('{{LANGUAGE}}', language)
    .replaceAll('{{DIRECTION}}', rtl ? 'rtl' : 'ltr')
    .replaceAll('{{ALIGN}}', rtl ? 'right' : 'left')
    .replace('{{LOGO_SPACING}}', rtl ? 'padding-left:18px;' : 'padding-right:18px;')
    .replace('{{BORDER_SIDE}}', rtl ? 'right' : 'left')
    .replaceAll('{{SUBJECT}}', escapeHtml(input.subject.trim()))
    .replace('{{PREHEADER}}', escapeHtml(input.preheader || input.subject.trim()))
    .replace('{{TITLE}}', escapeHtml(input.title.trim()))
    .replace('{{ORGANIZATION_LABEL}}', escapeHtml(input.organizationLabel || labels[language].organization))
    .replace('{{TYPE_LABEL}}', escapeHtml(input.typeLabel || labels[language][type]))
    .replaceAll('{{ACCENT_COLOR}}', styles[type].accent)
    .replace('{{BADGE_BACKGROUND}}', styles[type].background)
    .replace('{{MESSAGE_HTML}}', messageHtml)
    .replace('{{ACTION_BLOCK}}', actionBlock)
    .replace('{{FOOTER}}', escapeHtml(input.footer || labels[language].footer));

const emailMessage = {
    ...msg,
    to: [...new Set(input.recipients.map(value => value.trim().toLowerCase()))].join(','),
    from: input.from || 'notifications@parman.local',
    topic: input.subject.trim(),
    payload: html,
    attachments: [{
        filename: 'parman-logo.png',
        content: Buffer.from('__LOGO_BASE64__', 'base64'),
        contentType: 'image/png',
        cid: 'parman-logo'
    }]
};
delete emailMessage.req;
delete emailMessage.res;

const channels = Array.isArray(input.channels) ? input.channels : ['email'];
const emailOutput = channels.includes('email') ? emailMessage : null;

let telegramOutput = null;
if (channels.includes('telegram')) {
    const appSettings = global.get('appSettings') || {};
    const tg = appSettings.telegram || {};
    const botToken = tg.botToken || '';
    const chatId = tg.defaultChatId || '';
    if (botToken && chatId) {
        const tgEmoji = { info: '\u2139\uFE0F', success: '\u2705', warning: '\u26A0\uFE0F', urgent: '\uD83D\uDEA8' };
        const tgOrg = { fa: '\uD83D\uDCE3 \u0631\u0648\u0627\u0628\u0637 \u0639\u0645\u0648\u0645\u06CC \u067E\u0627\u0631\u0645\u0627\u0646', en: '\uD83D\uDCE3 Parman Public Relations' };
        const tgLines = [];
        tgLines.push(tgEmoji[type] + ' <b>' + escapeHtml(input.subject.trim()) + '</b>');
        tgLines.push('<i>' + escapeHtml(input.title.trim()) + '</i>');
        tgLines.push('\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500');
        paragraphs
            .filter(function(p) { return String(p).trim(); })
            .forEach(function(p) { tgLines.push(escapeHtml(String(p).trim())); });
        if (input.action) {
            tgLines.push('');
            tgLines.push('\uD83D\uDD17 <a href="' + escapeHtml(input.action.url) + '">' + escapeHtml(input.action.label) + '</a>');
        }
        tgLines.push('');
        tgLines.push('<i>' + (tgOrg[language] || tgOrg['en']) + '</i>');
        telegramOutput = {
            url: 'https://api.telegram.org/bot' + botToken + '/sendMessage',
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            payload: JSON.stringify({ chat_id: chatId, text: tgLines.join('\n'), parse_mode: 'HTML', link_preview_options: { is_disabled: true } })
        };
    }
}

const response = {
    ...msg,
    statusCode: 202,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    payload: {
        ok: true,
        message: 'Notification accepted for delivery',
        notification: {
            subject: input.subject.trim(),
            language,
            type,
            recipients: emailMessage.to.split(','),
            channels,
            hasAction: Boolean(input.action)
        }
    }
};
return [emailOutput, response, telegramOutput];
'@
$functionCode = $functionCode.Replace("__HTML_TEMPLATE_JSON__", $htmlTemplateJson)
$functionCode = $functionCode.Replace("__LOGO_BASE64__", $logoBase64)

$nodes = @(
    @{
        id = "checkpoint6c-tab"
        type = "tab"
        label = "Checkpoint 6C - Notifications"
        disabled = $false
        info = "Reusable bilingual branded notification API."
    },
    @{
        id = "checkpoint6c-comment"
        type = "comment"
        z = "checkpoint6c-tab"
        name = "POST /api/notifications/send - Persian/English, severity style, optional action button"
        info = "The POC currently delivers through email. Additional channel adapters can use the same payload later."
        x = 420
        y = 60
        wires = @()
    },
    @{
        id = "checkpoint6c-http-in"
        type = "http in"
        z = "checkpoint6c-tab"
        name = "Generic notification API"
        url = "/api/notifications/send"
        method = "post"
        upload = $false
        swaggerDoc = ""
        x = 160
        y = 140
        wires = @(, @("checkpoint6c-build"))
    },
    @{
        id = "checkpoint6c-build"
        type = "function"
        z = "checkpoint6c-tab"
        name = "Validate and build notification"
        func = $functionCode
        outputs = 3
        timeout = 0
        noerr = 0
        initialize = ""
        finalize = ""
        libs = @()
        x = 440
        y = 140
        wires = @(
            @("checkpoint6c-email"),
            @("checkpoint6c-response"),
            @("checkpoint6c-telegram-send")
        )
    },
    @{
        id = "checkpoint6c-email"
        type = "e-mail"
        z = "checkpoint6c-tab"
        server = "parman-mailpit"
        port = "1025"
        authtype = "NONE"
        saslformat = $false
        token = "oauth2Response.access_token"
        secure = $false
        tls = $false
        name = ""
        dname = "Send notification to Mailpit"
        x = 750
        y = 110
        wires = @()
    },
    @{
        id = "checkpoint6c-response"
        type = "http response"
        z = "checkpoint6c-tab"
        name = "Return notification result"
        statusCode = ""
        headers = @{}
        x = 750
        y = 180
        wires = @()
    },
    @{
        id = "checkpoint6c-telegram-send"
        type = "http request"
        z = "checkpoint6c-tab"
        name = "Send to Telegram"
        method = "POST"
        ret = "obj"
        paytoqs = "ignore"
        url = ""
        tls = ""
        persist = $false
        proxy = ""
        insecureHTTPParser = $false
        authType = ""
        senderr = $false
        headers = @()
        x = 750
        y = 250
        wires = @()
    }
)

$allFlows = @($flows) + $nodes
$json = $allFlows | ConvertTo-Json -Depth 40 -Compress
$body = [System.Text.Encoding]::UTF8.GetBytes($json)
Invoke-RestMethod -Method Post -Uri http://localhost:1880/flows `
    -ContentType "application/json; charset=utf-8" -Body $body | Out-Null

Write-Output "Generic notification API deployed."
