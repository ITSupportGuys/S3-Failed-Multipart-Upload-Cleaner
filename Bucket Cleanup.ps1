# Target the Amazon CLI Application Path
$exe = "$env:ProgramFiles\Amazon\AWSCLI\aws.exe"

# Setup Variables and Arrays
$curDate = Get-Date -UFormat "%Y-%m-%d"
$curUser = $env:UserName
$OutArray = @()

# List all buckets to an array
$bucketsArray = aws s3 ls

# Debug - Set to only one bucket
#$bucketsArray = "itsgbackup"
    

foreach ($bucket in $bucketsArray) {
    # Clean up the full string and just keep the bucket name
    $bucket = $bucket -replace '(?:\d\d\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d\s)', ''

    # Convert from JSON to object
    $bucketJSON = aws s3api list-multipart-uploads --bucket $bucket | ConvertFrom-Json
    
    # Loop through each faild multipart upload 
    foreach ($multiPartFile in $bucketJSON.Uploads) { 
        # Debug outputs
            #$multiPartFile.Key
            #$multiPartFile.UploadID
            #$multiPartFile.Initiated
            #$bucket

        # Compare Current date and upload start date
        $age = NEW-TIMESPAN –Start $curDate –End $multiPartFile.Initiated

        # Prints the difference in the age
        #$age.Days

        # Delete if older than 7 days
        #if ($age.Days -lt -7){
            
            # Build the arguments
            $args = @(
                's3api',
                'abort-multipart-upload',
                '--request-payer',
                'requester',
                '--bucket',
                $bucket,
                '--key',
                $multiPartFile.Key,
                '--upload-id',
                $multiPartFile.UploadID
            )

            # Delete the upload remnants
            & $exe $args

            # Build the array to export to a file
            $myobj = "" | Select "Bucket", "UploadID", "Initiated", "Key"
            $myobj.key = $multiPartFile.Key
            $myobj.uploadid = $multiPartFile.UploadID
            $myobj.initiated = $multiPartFile.Initiated
            $myobj.bucket = $bucket
            $OutArray += $myobj
            $myobj = $null

            #echo "Deleted"
        #}
        echo ""
    }

    # Export the deleted file information to CSV
    $OutArray | export-csv "c:\users\$curUser\desktop\Removed.$curDate.csv"
}