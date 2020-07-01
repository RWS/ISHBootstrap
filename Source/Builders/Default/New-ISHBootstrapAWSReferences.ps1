param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("12.0.3","12.0.4","13.0.0","13.0.1","13.0.2","14.0.0","14.0.1","14.0.2","15.0.0")]
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
            ISHCDFileName="20170528.CD.InfoShare.12.0.4128.4.Trisoft-DITA-OT.exe"
        }
    }
    '13.0.0' {
        $hash=@{
            BucketName="sct-released"
            ISHServerFolder="InfoShare/13.0/PreRequisites"
            ISHCDFolder="InfoShare/13.0/"
            ISHCDFileName="20171110.CD.InfoShare.13.0.3510.0.Trisoft-DITA-OT.exe"
        }
    }
    '13.0.1' {
        $hash=@{
            BucketName="sct-released"
            ISHServerFolder="InfoShare/13.0/PreRequisites"
            ISHCDFolder="InfoShare/13.0/"
            ISHCDFileName="20180515.CD.InfoShare.13.0.4115.1.Trisoft-DITA-OT.exe"
        }
    }
    '13.0.2' {
        $hash=@{
            BucketName="sct-released"
            ISHServerFolder="InfoShare/13.0/PreRequisites"
            ISHCDFolder="InfoShare/13.0/"
            ISHCDFileName="20181023.CD.InfoShare.13.0.4623.2.Trisoft-DITA-OT.exe"
        }
    }
    '14.0.0' {
        $hash=@{
            BucketName="sct-released"
            ISHServerFolder="InfoShare/14.0/PreRequisites"
            ISHCDFolder="InfoShare/14.0/"
            ISHCDFileName="20190705.CD.InfoShare.14.0.3105.0.Trisoft-DITA-OT.exe"
        }
    }
    '14.0.1' {
        $hash=@{
            BucketName="sct-released"
            ISHServerFolder="InfoShare/14.0/PreRequisites"
            ISHCDFolder="InfoShare/14.0/"
            ISHCDFileName="20191206.CD.InfoShare.14.0.3606.1.Trisoft-DITA-OT.exe"
        }
    }
    '14.0.2' {
        $hash=@{
            BucketName="sct-released"
            ISHServerFolder="InfoShare/14.0/PreRequisites"
            ISHCDFolder="InfoShare/14.0/"
            ISHCDFileName="20200501.CD.InfoShare.14.0.4101.2.Trisoft-DITA-OT.exe"
        }
    }
    '15.0.0' {
        $hash=@{
            BucketName="sct-notreleased"
            ISHServerFolder="InfoShare/15.0/PreRequisites"
            ISHCDFolder="InfoShare/15.0/"
            ISHCDFileName="20200630.CD.InfoShare.15.0.630.0.Trisoft-DITA-OT.exe"
        }
    }
}

New-Object -TypeName PSObject -Property $hash
