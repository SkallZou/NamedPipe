function ReadMsg([System.IO.StreamReader]$StreamReader){
    $msg = $StreamReader.ReadLine()
    if($msg -ne "stop"){
        Write-Host $msg
    }
}


$pipeName = "YahudPipe"
$pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream($pipeName)
Write-Host "Attempting to connect to the pipe..."
$pipeClient.Connect();
Write-Host "Connected."
$sw = New-Object System.IO.StreamWriter($pipeClient)
$sr = New-Object System.IO.StreamReader($pipeClient)
$sw.WriteLine("Olivier")
$sw.AutoFlush = $true # Without autoflush, buffer will flush when the pipe is close, autoflush is necessary for interactive session

while($pipeClient.IsConnected){
    ReadMsg($sr)
}

$sr.Dispose();
$pipeClient.Dispose();