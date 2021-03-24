Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
foreach($psbp in $PSBoundParameters.GetEnumerator()){Write-Debug "$($psbp.Key)=$($psbp.Value)"}