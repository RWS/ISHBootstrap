param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("12.0.3","12.0.4","13.0.0")]
    [string]$ISHVersion
)

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

switch($ISHVersion) {
    '12.0.3' {
        $hash=@{
            BucketName="sct-released"
            ISHServerFolder="InfoShare/12.0/PreRequisites"
            ISHCDFolder="InfoShare/12.0/"
            ISHCDFileName="20170125.CD.InfoShare.12.0.3725.3.Trisoft-DITA-OT.exe"
        }
    }
    '12.0.4' {
        $hash=@{
            BucketName="sct-released"
            ISHServerFolder="InfoShare/12.0/PreRequisites"
            ISHCDFolder="InfoShare/12.0/"
            ISHCDFileName="20170302.CD.InfoShare.12.0.3902.4.Prod.Trisoft-DITA-OT.exe"
        }
    }
    '13.0.0' {
        $hash=@{
            BucketName="sct-notreleased"
            ISHServerFolder="InfoShare/13.0/PreRequisites"
            ISHCDFolder="InfoShare/13.0/"
            ISHCDFileName="20170202.CD.InfoShare.13.0.2602.0.Test.Trisoft-DITA-OT.exe"
        }
    }
}

New-Object -TypeName PSObject -Property $hash
