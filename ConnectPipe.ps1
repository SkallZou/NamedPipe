$pipeName = "YahudPipe"
$pipe = New-Object System.IO.Pipes.NamedPipeClientStream($pipeName)
$pipe.Connect();

$sw = New-Object System.IO.StreamWriter($pipe);
$msg = Read-Host "Enter your message to send";
$sw.WriteLine($msg)

$sw.Dispose()
$pipe.Dispose()