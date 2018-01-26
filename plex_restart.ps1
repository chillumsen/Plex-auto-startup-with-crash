# Set Plex Media Server process name
$plex_process = "Plex"

# Set Plex Media Server executable path
$plex_path = "C:\Program Files (x86)\Plex\Plex Media Server\Plex Media Server.exe"

# Set Plex Media Server test URI
$plex_uri = "http://127.0.0.1:32400/library/sections"

# Set Timeout for response from test URI (in seconds)
$plex_timeout = 10

# Set logfile (Make sure it's writeable)
$Logfile = "C:\Users\PMS\$(gc env:computername)-plex-crash.log"

# How often to check Plex Media Server URI (in milliseconds)
$sleep = 5000

# Logwrite function
Function LogWrite
{
   Param ([string]$logstring)
   $timestamp = (Get-Date).toString('yyyy/MM/dd HH:mm:ss')

   Add-content $Logfile -passthru -value "$timestamp $logstring"
}

# Main loop
Write-Host "Plex Media Server Watchdog"

while($true)
{
    # Check if Plex Media Server is responding
    try {
        Invoke-RestMethod -TimeoutSec $plex_timeout -Uri $plex_uri -Method Get
    } catch {
        # Check for 401 Response Code
        if (($_.Exception.Response.StatusCode.value__ -NE 401)) {

            # Log and kill Plex Media Server process
            LogWrite ""
            LogWrite "$plex_process is unresponsive"
            LogWrite "Killing $plex_process process"

            # Find Plex Media Server process
            $plex_pid = (Get-Process | Where-Object { $_.Name -EQ "$plex_process" } | Select-Object -First 1).id

            # Kill Plex Media Server process
            if($plex_pid) {
                foreach($pid in $plex_pid) {
                    Stop-Process $plex_pid
                    Wait-Process $plex_pid
                    LogWrite "Process killed [$pid]"
                }
            } else {
                LogWrite "Unable to find $plex_process process id"
            }

            # Start Plex Media Server
            LogWrite "Starting $plex_process"
            Start-Process -FilePath $plex_path
            LogWrite "$plex_process started"
        }
    }

    # Sleep
    Start-Sleep -m $sleep
}