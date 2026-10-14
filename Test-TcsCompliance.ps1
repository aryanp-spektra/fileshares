<#
  Test-TcsCompliance.ps1
  Read-only check, run ON the lab Jump Box VM. Compares what the lab resolver actually
  does against the TCS Zscaler category sheet, plus the bypass paths DNS filtering can't see.
  Output: summary on screen, full results in C:\Temp\tcs-compliance-<time>.csv
#>
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'

# Expect: Block = TCS blocks it | Allow = lab needs it | TCSAllow = TCS allows it (blocking it is just stricter)
$tests = @(
  # --- Zscaler Blocked categories -------------------------------------------------------------
  @('Entertainment','imdb.com','Block'), @('Music and Audio Streaming','spotify.com','Block'),
  @('Radio','iheart.com','Block'), @('Television/Movies','netflix.com','Block'),
  @('Video Streaming','youtube.com','Block'), @('Video Streaming','twitch.tv','Block'),
  @('Developer Tools','gitlab.com','Block'), @('Developer Tools','vscode.dev','Block'),
  @('Developer Tools','bitbucket.org','Block'),
  @('DNS Over HTTPS Services','dns.google','Block'), @('DNS Over HTTPS Services','cloudflare-dns.com','Block'),
  @('DNS Over HTTPS Services','dns.quad9.net','Block'), @('DNS Over HTTPS Services','use-application-dns.net','Block'),
  @('File Convertors','cloudconvert.com','Block'), @('File Convertors','ilovepdf.com','Block'),
  @('File Host','dropbox.com','Block'), @('File Host','mega.nz','Block'), @('File Host','wetransfer.com','Block'),
  @('File Host','drive.google.com','Block'), @('File Host','onedrive.live.com','Block'),
  @('File Host (allowlist check)','sharepoint.com','Block'),
  @('Generative AI','chatgpt.com','Block'), @('Generative AI','claude.ai','Block'),
  @('Generative AI','gemini.google.com','Block'), @('Generative AI','perplexity.ai','Block'),
  @('Generative AI','copilot.microsoft.com','Block'), @('Generative AI','deepseek.com','Block'),
  @('Image Host','imgur.com','Block'), @('Image Host','i.imgur.com','Block'), @('Image Host','ibb.co','Block'),
  @('Online Chat','web.whatsapp.com','Block'), @('Online Chat','discord.com','Block'),
  @('Online Chat','web.telegram.org','Block'), @('Online Chat','slack.com','Block'),
  @('OS and Software Updates','download.windowsupdate.com','Block'), @('OS and Software Updates','update.microsoft.com','Block'),
  @('Peer-to-Peer','bittorrent.com','Block'), @('Peer-to-Peer','utorrent.com','Block'),
  @('Remote Access Tools','anydesk.com','Block'), @('Remote Access Tools','teamviewer.com','Block'),
  @('Remote Access Tools','ngrok.com','Block'),
  @('Shareware Download','softonic.com','Block'), @('Shareware Download','filehippo.com','Block'),
  @('Web Host','netlify.app','Block'), @('Web Host','herokuapp.com','Block'), @('Web Host','000webhostapp.com','Block'),
  @('Webmail','mail.google.com','Block'), @('Webmail','outlook.live.com','Block'),
  @('Webmail (allowlist check)','outlook.office.com','Block'), @('Webmail','mail.yahoo.com','Block'),
  @('Webmail','proton.me','Block'),
  @('Military','army.mil','Block'),
  @('Anonymizer','nordvpn.com','Block'), @('Anonymizer','torproject.org','Block'), @('Anonymizer','croxyproxy.com','Block'),
  @('Computer Hacking','exploit-db.com','Block'),
  @('Copyright Infringement','thepiratebay.org','Block'), @('Copyright Infringement','1337x.to','Block'),
  @('Gambling','bet365.com','Block'), @('Gambling','pokerstars.com','Block'),
  @('Drugs/Marijuana','leafly.com','Block'),
  @('Adult (vendor test host)','nudity.testcategory.com','Block'),
  @('Weapons','gunbroker.com','Block'),
  @('Dynamic DNS Host','duckdns.org','Block'), @('Dynamic DNS Host','no-ip.com','Block'),
  @('Malware (vendor test host)','malware.testcategory.com','Block'),
  @('Phishing (vendor test host)','phishing.testcategory.com','Block'),
  @('Cryptomining and Blockchain','coinbase.com','Block'), @('Cryptomining and Blockchain','binance.com','Block'),
  @('Alcohol/Tobacco','budweiser.com','Block'),
  @('Online and Other Games','store.steampowered.com','Block'), @('Online and Other Games','roblox.com','Block'),
  @('Online Shopping','amazon.com','Block'), @('Online Auctions','ebay.com','Block'),
  @('Social Networking','facebook.com','Block'), @('Social Networking','instagram.com','Block'),
  @('Social Networking','x.com','Block'), @('Social Networking','linkedin.com','Block'),
  @('Social Networking','reddit.com','Block'), @('Social Networking','www.facebook.com','Block'),
  @('Social Networking Adult','tinder.com','Block'),
  @('Paste sites (custom list)','pastebin.com','Block'), @('Paste sites (custom list)','www.pastebin.com','Block'),
  @('URL shorteners','bit.ly','Block'),
  # --- Lab must stay usable ------------------------------------------------------------------
  @('LAB REQUIRED','login.microsoftonline.com','Allow'), @('LAB REQUIRED','portal.azure.com','Allow'),
  @('LAB REQUIRED','management.azure.com','Allow'), @('LAB REQUIRED','ai.azure.com','Allow'),
  @('LAB REQUIRED','learn.microsoft.com','Allow'), @('LAB REQUIRED','github.com','Allow'),
  @('LAB REQUIRED','raw.githubusercontent.com','Allow'), @('LAB REQUIRED','pypi.org','Allow'),
  @('LAB REQUIRED','files.pythonhosted.org','Allow'), @('LAB REQUIRED','go.microsoft.com','Allow'),
  # --- Zscaler Allowed categories (blocking = stricter than TCS, not a failure) --------------
  @('News and Media','bbc.com','TCSAllow'), @('Reference Sites','wikipedia.org','TCSAllow'),
  @('Translators','translate.google.com','TCSAllow'), @('Job Search','naukri.com','TCSAllow'),
  @('Travel','booking.com','TCSAllow'), @('Finance','hdfcbank.com','TCSAllow'),
  @('Government','india.gov.in','TCSAllow'), @('Web Conferencing','zoom.us','TCSAllow'),
  @('Discussion Forums','stackoverflow.com','TCSAllow'), @('Health','webmd.com','TCSAllow')
)

function Get-A([string]$name, [string]$server) {
  $p = @{ Name = $name; Type = 'A'; DnsOnly = $true; QuickTimeout = $true; NoHostsFile = $true; ErrorAction = 'Stop' }
  if ($server) { $p.Server = $server }
  try { @((Resolve-DnsName @p) | Where-Object { $_.Type -eq 'A' } | ForEach-Object IPAddress) }
  catch { $null }
}
function Test-Tcp([string]$target, [int]$port) {
  $c = New-Object Net.Sockets.TcpClient
  try { $ok = $c.ConnectAsync($target, $port).Wait(3000); $ok -and $c.Connected } catch { $false } finally { $c.Close() }
}

# --- 1. Learn the Gateway block signature from domains that must be blocked -------------------
$controls = 'facebook.com','chatgpt.com','dropbox.com','mail.google.com'
$sig = $controls | ForEach-Object { Get-A $_ } | Group-Object | Where-Object Count -ge 3 | ForEach-Object Name
$sig = @($sig) + '0.0.0.0'
Write-Host "Block signature (A): $($sig -join ', ')" -ForegroundColor Cyan

# --- 2. Category tests -----------------------------------------------------------------------
$rows = foreach ($t in $tests) {
  $cat, $dom, $exp = $t
  $ips = Get-A $dom
  $state =
    if ($null -eq $ips -or $ips.Count -eq 0) {
      # No answer: blocked, or the name just doesn't exist. Ask an unfiltered resolver to tell them apart.
      if (Get-A $dom '1.1.1.1') { 'Blocked' } else { 'NoRecord' }
    } elseif (@($ips | Where-Object { $_ -in $sig }).Count -gt 0) { 'Blocked' } else { 'Allowed' }
  $verdict = switch ($exp) {
    'Block'    { if ($state -eq 'Blocked') { 'PASS' } elseif ($state -eq 'NoRecord') { 'CHECK' } else { 'FAIL' } }
    'Allow'    { if ($state -eq 'Allowed') { 'PASS' } else { 'FAIL' } }
    'TCSAllow' { if ($state -eq 'Allowed') { 'PASS' } else { 'STRICTER' } }
  }
  [pscustomobject]@{ Verdict = $verdict; Expect = $exp; Category = $cat; Domain = $dom; Result = $state; IPs = ($ips -join ' ') }
}

# --- 3. Bypass paths (things the DNS filter cannot see) ----------------------------------------
$bypass = @()
$nicDns = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object ServerAddresses).ServerAddresses | Select-Object -Unique
$bypass += [pscustomobject]@{ Check = 'NIC DNS servers'; Value = ($nicDns -join ', '); Verdict = $(if (@($nicDns).Count -eq 1) { 'PASS' } else { 'FAIL' }) }

$direct = Get-A 'facebook.com' '8.8.8.8'
$bypass += [pscustomobject]@{ Check = 'Direct DNS to 8.8.8.8 (facebook.com)'; Value = $(if ($direct) { $direct -join ' ' } else { 'no answer' })
  Verdict = $(if ($direct -and -not ($direct | Where-Object { $_ -in $sig })) { 'FAIL' } else { 'PASS' }) }

$dot = Test-Tcp '1.1.1.1' 853
$bypass += [pscustomobject]@{ Check = 'DNS-over-TLS to 1.1.1.1:853'; Value = $(if ($dot) { 'open' } else { 'closed' }); Verdict = $(if ($dot) { 'FAIL' } else { 'PASS' }) }

$doh = $null
try { $doh = Invoke-RestMethod 'https://1.1.1.1/dns-query?name=facebook.com&type=A' -Headers @{ accept = 'application/dns-json' } -TimeoutSec 5 } catch {}
$bypass += [pscustomobject]@{ Check = 'DNS-over-HTTPS by IP (1.1.1.1)'; Value = $(if ($doh.Answer) { ($doh.Answer.data -join ' ') } else { 'no answer' }); Verdict = $(if ($doh.Answer) { 'FAIL' } else { 'PASS' }) }

foreach ($p in 25, 587, 465) {
  $o = Test-Tcp '142.250.102.108' $p   # smtp.gmail.com by IP, so DNS blocking doesn't hide it
  $bypass += [pscustomobject]@{ Check = "Outbound SMTP port $p (by IP)"; Value = $(if ($o) { 'open' } else { 'closed' }); Verdict = $(if ($o) { 'FAIL' } else { 'PASS' }) }
}
$ssh = Test-Tcp 'github.com' 22
$bypass += [pscustomobject]@{ Check = 'git over SSH to github.com:22'; Value = $(if ($ssh) { 'open' } else { 'closed' }); Verdict = $(if ($ssh) { 'WARN' } else { 'PASS' }) }

foreach ($b in @{ n = 'Edge'; k = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' }, @{ n = 'Chrome'; k = 'HKLM:\SOFTWARE\Policies\Google\Chrome' }) {
  $v = (Get-ItemProperty $b.k -Name DnsOverHttpsMode).DnsOverHttpsMode
  $bypass += [pscustomobject]@{ Check = "$($b.n) DnsOverHttpsMode policy"; Value = $(if ($v) { $v } else { 'not set' }); Verdict = $(if ($v -eq 'off') { 'PASS' } else { 'FAIL' }) }
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$bypass += [pscustomobject]@{ Check = 'Current user is local admin (can change DNS / hosts file)'; Value = "$env:USERNAME = $isAdmin"; Verdict = $(if ($isAdmin) { 'WARN' } else { 'PASS' }) }

# --- 4. Report -------------------------------------------------------------------------------
New-Item -ItemType Directory -Force C:\Temp | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
$rows   | Export-Csv "C:\Temp\tcs-compliance-$stamp.csv" -NoTypeInformation
$bypass | Export-Csv "C:\Temp\tcs-bypass-$stamp.csv" -NoTypeInformation

Write-Host "`n=== Category results ===" -ForegroundColor Cyan
$rows | Group-Object Verdict | ForEach-Object { '{0,-9} {1}' -f $_.Name, $_.Count }
Write-Host "`n--- Not as expected ---" -ForegroundColor Yellow
$rows | Where-Object Verdict -in 'FAIL','CHECK' | Format-Table Verdict, Category, Domain, Result, IPs -AutoSize | Out-String -Width 200
Write-Host "--- Stricter than TCS (info only) ---" -ForegroundColor DarkGray
($rows | Where-Object Verdict -eq 'STRICTER' | ForEach-Object Domain) -join ', '
Write-Host "`n=== Bypass checks ===" -ForegroundColor Cyan
$bypass | Format-Table Verdict, Check, Value -AutoSize | Out-String -Width 200
Write-Host "Full results: C:\Temp\tcs-compliance-$stamp.csv and C:\Temp\tcs-bypass-$stamp.csv"
