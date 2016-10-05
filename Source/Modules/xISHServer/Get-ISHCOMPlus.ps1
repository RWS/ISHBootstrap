function Get-ISHCOMPlus
{
    $comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
    $Catalog = New-Object -com COMAdmin.COMAdminCatalog 
    $oapplications = $catalog.getcollection("Applications") 
    $oapplications.populate()
    foreach ($oapplication in $oapplications){ 
        $hash=[ordered]@{
            Name=$oapplication.Name
            IsValid=[bool]($oapplication.Valid)
            IsEnabled=[bool]($oapplication.Value("IsEnabled"))
        }

        $skeyappli = $oapplication.key 
        $oappliInstances = $oapplications.getcollection("ApplicationInstances",$skeyappli) 
        $oappliInstances.populate() 
        $hash.IsRunning=$oappliInstances.count -gt 0

        New-Object -TypeName PSObject -Property $hash
    }
}