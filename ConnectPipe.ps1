$pipeName = "YahudPipe"
$pipe = New-Object System.IO.Pipes.NamedPipeClientStream($pipeName)
$pipe.Connect();
$sw = New-Object System.IO.StreamWriter($pipe);
$sw.WriteLine("Olivier")
$sw.AutoFlush = $true # Without autoflush, buffer will flush when the pipe is close, autoflush is necessary for interactive session

while($pipe.IsConnected){
$msg = Read-Host "Enter your message to send";
$sw.WriteLine($msg)
    if($msg -eq "exit"){
        $sw.Dispose()
        $pipe.Dispose()
    }
}
