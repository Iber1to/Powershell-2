#requiere permisos de administrador. 
#Sacar la comprobacion de usuario ZX y que la consola tiene permisos elevados fuera de las funciones
#al principio de todo


Function ConectCAS
{
$CurrentUser = $env:UserName
if($CurrentUser.substring(0,2) -eq 'ZX'){
    #Conecta al CAS
    $SiteCode = "CAS" # Site code 
    $ProviderMachineName = "SRV004.contoso.local" # SMS Provider machine name
    $initParams = @{}
    
    # Import the ConfigurationManager.psd1 module 
    if((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
    }

    # Connect to the site's drive if it is not already present
    if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
    }

    # Set the current location to be the site code.
    Set-Location "$($SiteCode):\" @initParams
    }
else{
    write-host " El usuario actual es $CurrentUser y deber ser un 'ZX' para ejecutar el Script" -ForegroundColor Red
    Break
    }
}
Function Test-RPC
{
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param([Parameter(ValueFromPipeline=$True)][String[]]$ComputerName = 'localhost')
    BEGIN
    {
        Set-StrictMode -Version Latest
        $PInvokeCode = @'
        using System;
        using System.Collections.Generic;
        using System.Runtime.InteropServices;

        public class Rpc
        {
            // I found this crud in RpcDce.h

            [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
            public static extern int RpcBindingFromStringBinding(string StringBinding, out IntPtr Binding);

            [DllImport("Rpcrt4.dll")]
            public static extern int RpcBindingFree(ref IntPtr Binding);

            [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
            public static extern int RpcMgmtEpEltInqBegin(IntPtr EpBinding,
                                                    int InquiryType, // 0x00000000 = RPC_C_EP_ALL_ELTS
                                                    int IfId,
                                                    int VersOption,
                                                    string ObjectUuid,
                                                    out IntPtr InquiryContext);

            [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
            public static extern int RpcMgmtEpEltInqNext(IntPtr InquiryContext,
                                                    out RPC_IF_ID IfId,
                                                    out IntPtr Binding,
                                                    out Guid ObjectUuid,
                                                    out IntPtr Annotation);

            [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
            public static extern int RpcBindingToStringBinding(IntPtr Binding, out IntPtr StringBinding);

            public struct RPC_IF_ID
            {
                public Guid Uuid;
                public ushort VersMajor;
                public ushort VersMinor;
            }

            public static List<int> QueryEPM(string host)
            {
                List<int> ports = new List<int>();
                int retCode = 0; // RPC_S_OK                
                IntPtr bindingHandle = IntPtr.Zero;
                IntPtr inquiryContext = IntPtr.Zero;                
                IntPtr elementBindingHandle = IntPtr.Zero;
                RPC_IF_ID elementIfId;
                Guid elementUuid;
                IntPtr elementAnnotation;

                try
                {                    
                    retCode = RpcBindingFromStringBinding("ncacn_ip_tcp:" + host, out bindingHandle);
                    if (retCode != 0)
                        throw new Exception("RpcBindingFromStringBinding: " + retCode);

                    retCode = RpcMgmtEpEltInqBegin(bindingHandle, 0, 0, 0, string.Empty, out inquiryContext);
                    if (retCode != 0)
                        throw new Exception("RpcMgmtEpEltInqBegin: " + retCode);
                    
                    do
                    {
                        IntPtr bindString = IntPtr.Zero;
                        retCode = RpcMgmtEpEltInqNext (inquiryContext, out elementIfId, out elementBindingHandle, out elementUuid, out elementAnnotation);
                        if (retCode != 0)
                            if (retCode == 1772)
                                break;

                        retCode = RpcBindingToStringBinding(elementBindingHandle, out bindString);
                        if (retCode != 0)
                            throw new Exception("RpcBindingToStringBinding: " + retCode);
                            
                        string s = Marshal.PtrToStringAuto(bindString).Trim().ToLower();
                        if(s.StartsWith("ncacn_ip_tcp:"))                        
                            ports.Add(int.Parse(s.Split('[')[1].Split(']')[0]));
                        
                        RpcBindingFree(ref elementBindingHandle);
                        
                    }
                    while (retCode != 1772); // RPC_X_NO_MORE_ENTRIES

                }
                catch(Exception ex)
                {
                    Console.WriteLine(ex);
                    return ports;
                }
                finally
                {
                    RpcBindingFree(ref bindingHandle);
                }
                
                return ports;
            }
        }
'@
    }
    PROCESS
    {
        ForEach($Computer In $ComputerName)
        {
            If($PSCmdlet.ShouldProcess($Computer))
            {
                [Bool]$EPMOpen = $False
                $Socket = New-Object Net.Sockets.TcpClient
                
                Try
                {                    
                    $Socket.Connect($Computer, 135)
                    If ($Socket.Connected)
                    {
                        $EPMOpen = $True
                    }
                    $Socket.Close()                    
                }
                Catch
                {
                    $Socket.Dispose()
                }
                
                If ($EPMOpen)
                {
                    Add-Type $PInvokeCode
                    $RPCPorts = [Rpc]::QueryEPM($Computer)
                    [Bool]$AllPortsOpen = $True
                    Foreach ($Port In $RPCPorts)
                    {
                        $Socket = New-Object Net.Sockets.TcpClient
                        Try
                        {
                            $Socket.Connect($Computer, $Port)
                            If (!$Socket.Connected)
                            {
                                $AllPortsOpen = $False
                            }
                            $Socket.Close()
                        }
                        Catch
                        {
                            $AllPortsOpen = $False
                            $Socket.Dispose()
                        }
                    }

                    [PSObject]@{'ComputerName' = $Computer; 'EndPointMapperOpen' = $EPMOpen; 'RPCPortsInUse' = $RPCPorts; 'AllRPCPortsOpen' = $AllPortsOpen}
                }
                Else
                {
                    [PSObject]@{'ComputerName' = $Computer; 'EndPointMapperOpen' = $EPMOpen}
                }
            }
        }
    }
    END
    {

    }
}


ConectCAS
$SiteCode = 'PE1'
$DistributionPointsList = (Get-CMDistributionPointInfo -SiteCode $SiteCode | Select-Object Name | Sort-Object name).Name


Foreach($DP in $DistributionPointsList){
$testconection = Test-RPC $DP
    If(($testconection.EndPointMapperOpen -eq $true) -and ($testconection.AllRPCPortsOpen -eq $true)){
    
$WMIPkgList = Get-WmiObject -ComputerName $DP  -Namespace Root\SCCMDP -Class SMS_PackagesInContLib | Select -ExpandProperty PackageID | Sort-Object 
$ContentLib = (Invoke-Command -ComputerName $DP {Get-ItemProperty -path HKLM:SOFTWARE\Microsoft\SMS\DP -Name ContentLibraryPath})
$PkgLibPath = ($ContentLib.ContentLibraryPath) + "\PkgLib"
$PkgLibList = Invoke-Command -ComputerName $DP {Get-ChildItem $args[0] | Select -ExpandProperty Name | Sort-Object} -ArgumentList $PkgLibPath
$PkgLibList = ($PKgLibList | ForEach-Object {$_.replace(".INI","")})
$PksinWMIButNotContentLib = Compare-Object -ReferenceObject $WMIPkgList -DifferenceObject $PKgLibList -PassThru | Where-Object { $_.SideIndicator -eq "<=" } 
$PksinContentLibButNotWMI = Compare-Object -ReferenceObject $WMIPkgList -DifferenceObject $PKgLibList -PassThru | Where-Object { $_.SideIndicator -eq "=>" }
}

#Borrando las inconsistencias
Write-host "Conectado al servidor:  $DP"
Write-Host 'Borrando estas entradas en WMI:'
$PksinWMIButNotContentLib
foreach ($item in $PksinWMIButNotContentLib){
try{
Get-WMIObject -ComputerName $DP -Namespace "root\sccmdp" -Query ("Select * from SMS_PackagesInContLib where PackageID = '$item'") | Remove-WmiObject
Write-host "Borrando item de WMI: $item" -ForegroundColor Green
}
Catch{Write-host "Borrando item de WMI: $item HA FALLADO" -ForegroundColor Red}
}


Write-Host 'Borrando archivos .INI  de estos paquetes en la carpeta PkgLib:'
$PksinContentLibButNotWMI
foreach ($item in $PksinContentLibButNotWMI){
$PathLibpathini = "$PkgLibPath\$item.ini"
$PathLibpath = "$PkgLibPath\$item"
$TestPathLibpath = Invoke-Command -ComputerName $DP {Test-Path -Path $args[0]} -ArgumentList $PathLibpath
$TestPathLibpathini = Invoke-Command -ComputerName $DP {Test-Path -Path $args[0]} -ArgumentList $PathLibpathini
if($TestPathLibpathini -eq $true){
Invoke-Command -ComputerName $DP {Remove-Item -Path $args[0]} -ArgumentList $PathLibpath
Write-Host "Borrando item de PKGLIB: '$PkgLibPath\$item'" -ForegroundColor Green
}
elseif($TestPathLibpath -eq $true){
Invoke-Command -ComputerName $DP {Remove-Item -Path $args[0]} -ArgumentList $PathLibpath
Write-Host "Borrando item de PKGLIB: '$PkgLibPath\$item'" -ForegroundColor Green
}
else{Write-Host "Borrando item de PKGLIB: '$PkgLibPath\$item' HA FALLADO" -ForegroundColor Red}                                              

}
}




<##>


                                              