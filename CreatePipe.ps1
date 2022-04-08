function ReadMsg([System.IO.StreamReader]$StreamReader){
    $msg = $StreamReader.ReadLine()
    Write-Host $msg
}


try{
    $pipeName = "YahudPipe";
    $pipe = New-Object System.IO.Pipes.NamedPipeServerStream($pipeName); # Creation new pipe object
    Write-Host "Listening on \\.pipe\$pipeName";
    $pipe.WaitForConnection();
    $sr = New-Object System.IO.StreamReader($pipe) # StreamReader read text from a file, from $pipe here
    $user = $sr.ReadLine()
    Write-Host "Connection Established... from", $user



    while ($pipe.IsConnected){
        ReadMsg($sr)
    }

    $sr.Dispose();
    $pipe.Dispose();

}
catch{
    Write-Host "Failed to create the pipe $pipeName"
    return 0;
}