try{
$pipeName = "YahudPipe";
$pipe = New-Object System.IO.Pipes.NamedPipeServerStream($pipeName); # Creation new pipe object
Write-Host "Listening on \\.pipe\$pipeName";
$pipe.WaitForConnection();
$sr = New-Object System.IO.StreamReader($pipe) # StreamReader read text from a file, from $pipe here
$msg = $sr.ReadLine();
Write-Host "Message received :", $msg;
$sr.Dispose();
$pipe.Dispose();
}
catch{
Write-Host "Failed to create the pipe $pipeName"
$_
return 0;
}