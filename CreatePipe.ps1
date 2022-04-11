function ReadMsg([System.IO.StreamReader]$StreamReader){
    $msg = $StreamReader.ReadLine()
    Write-Host $msg
}

try{
    $pipeName = "YahudPipe";
    $pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream($pipeName); # Creation new pipe object
    Write-Host "Listening on \\.pipe\$pipeName";
    $pipeServer.WaitForConnection();
    $sr = New-Object System.IO.StreamReader($pipeServer) # StreamReader read text from a file, from $pipe here
    $sw = New-Object System.IO.StreamWriter($pipeServer)
    $user = $sr.ReadLine()
    Write-Host "Connection Established... from", $user

    $sw.AutoFlush=$true

    while ($pipeServer.IsConnected){
        $action = Read-Host "What action do you want to do ?
        1. Run Malicious code
        2. Send message to client
        3. Quit
        "
        
        if ($action -eq 1){
            Write-Host "Uploading malicious payload to client"
            Add-Type -outputtype consoleapplication -outputassembly helloworld.exe 'public class helloworld{public static void Main(){System.Console.WriteLine("Hello World !");}}'
        }
        elseif ($action -eq 2){
            while($msg -ne "stop"){
                $msg = Read-Host "Enter your message to send"
                $sw.WriteLine($msg)
            }
        }
        else{
            if(Test-Path -Path .\helloworld.exe -PathType Leaf){
                Write-Host "File exist, deleting..."
                $command = 'del .\helloworld.exe'
                Invoke-Expression $command
            }
            $sw.WriteLine("Disconnected.")
            $sw.Dispose()
            $pipeServer.Dispose()
        }
    }

    $sr.Dispose();
    $pipeServer.Dispose();

}

catch{
    Write-Host "Failed to create the pipe $pipeName"
    return 0;
}