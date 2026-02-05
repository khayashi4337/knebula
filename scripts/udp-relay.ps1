# UDP Relay: Forward UDP 4242 from Windows to WSL2
# =================================================
# Required when running Nebula Lighthouse in WSL2
# Run as Administrator in PowerShell
#
# Usage:
#   cd C:\nebula
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\udp-relay.ps1

# Configuration - UPDATE THIS!
# Get WSL2 IP by running 'hostname -I' in WSL2
$wslIP = "172.31.x.x"  # <-- Change this to your WSL2 IP
$port = 4242

# Validate configuration
if ($wslIP -match "x\.x") {
    Write-Host "ERROR: Please update `$wslIP in this script!" -ForegroundColor Red
    Write-Host "Run 'hostname -I' in WSL2 to get the IP address." -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Nebula UDP Relay ===" -ForegroundColor Green
Write-Host "Listening on 0.0.0.0:$port"
Write-Host "Forwarding to ${wslIP}:$port"
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

$listener = New-Object System.Net.Sockets.UdpClient($port)
$listener.Client.ReceiveTimeout = 1000
$wslEndpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($wslIP), $port)
$clients = @{}

while ($true) {
    try {
        $clientEP = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        $data = $listener.Receive([ref]$clientEP)
        $clientKey = $clientEP.ToString()
        $now = Get-Date

        if ($clientEP.Address.ToString() -eq $wslIP) {
            # Response from WSL2 - forward to all known clients
            foreach ($key in $clients.Keys) {
                $listener.Send($data, $data.Length, $clients[$key].Endpoint) | Out-Null
                Write-Host "$(Get-Date -Format 'HH:mm:ss') <- WSL2 -> $key ($($data.Length) bytes)"
            }
        } else {
            # Request from client - forward to WSL2
            $clients[$clientKey] = @{Endpoint = $clientEP; LastSeen = $now}
            $listener.Send($data, $data.Length, $wslEndpoint) | Out-Null
            Write-Host "$(Get-Date -Format 'HH:mm:ss') $clientKey -> WSL2 ($($data.Length) bytes)"
        }

        # Cleanup old clients (older than 5 minutes)
        $cutoff = $now.AddMinutes(-5)
        $oldClients = $clients.Keys | Where-Object { $clients[$_].LastSeen -lt $cutoff }
        foreach ($old in $oldClients) { $clients.Remove($old) }
    }
    catch [System.Net.Sockets.SocketException] { }
    catch { Write-Host "Error: $_" -ForegroundColor Red }
}
