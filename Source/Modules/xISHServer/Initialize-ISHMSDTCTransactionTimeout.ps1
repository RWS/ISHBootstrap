function Initialize-ISHMSDTCTransactionTimeout
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-BD82DCF1-B23C-4877-892B-DCC9FC1F0926
    # http://stackoverflow.com/questions/20791497/use-powershell-to-set-component-services-transaction-timeout
    Write-Debug "Setting MSDTC Transaction Timeout to 3600"
    $comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
    $LocalColl = $comAdmin.Connect("localhost")
    $LocalComputer = $LocalColl.GetCollection("LocalComputer",$LocalColl.Name)
    $LocalComputer.Populate()

    $LocalComputerItem = $LocalComputer.Item(0)
    $CurrVal = $LocalComputerItem.Value("TransactionTimeout")

    $LocalComputerItem.Value("TransactionTimeout") = 3600
    $LocalComputer.SaveChanges()|Out-Null
    $newTimeout=$LocalComputerItem.Value("TransactionTimeout")
    Write-Verbose "Set MSDTC Transaction Timeout to $newTimeout"
}