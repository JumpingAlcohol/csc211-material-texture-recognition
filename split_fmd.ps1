param(
    [string]$SourceRoot = (Join-Path $PSScriptRoot "FMD\\image"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "FMD_split")
)

$classes = Get-ChildItem -LiteralPath $SourceRoot -Directory | Sort-Object Name
if ($classes.Count -ne 10) {
    throw "Expected 10 material-class folders in $SourceRoot; found $($classes.Count)."
}
if (Test-Path -LiteralPath $OutputRoot) {
    throw "Output folder already exists: $OutputRoot. Refusing to overwrite an existing split."
}

New-Item -ItemType Directory -Path $OutputRoot | Out-Null
foreach ($split in @("train", "validation", "test_blinded", "metadata")) {
    New-Item -ItemType Directory -Path (Join-Path $OutputRoot $split) | Out-Null
}

$allRows = @()
$testRows = @()
$testNumber = 1

foreach ($class in $classes) {
    $images = Get-ChildItem -LiteralPath $class.FullName -File -Filter "*.jpg" |
        ForEach-Object {
            $hashBytes = [System.Security.Cryptography.SHA256]::HashData(
                [System.Text.Encoding]::UTF8.GetBytes("CSC211-FMD-2026|$($class.Name)|$($_.Name)"))
            [PSCustomObject]@{ File = $_; SortKey = [Convert]::ToHexString($hashBytes) }
        } |
        Sort-Object SortKey

    if ($images.Count -ne 100) {
        throw "Expected 100 images for $($class.Name); found $($images.Count)."
    }

    for ($index = 0; $index -lt $images.Count; $index++) {
        $image = $images[$index].File
        if ($index -lt 5) {
            $split = "test"
            $destinationName = "test_{0:D3}.jpg" -f $testNumber
            Copy-Item -LiteralPath $image.FullName -Destination (Join-Path $OutputRoot "test_blinded\\$destinationName")
            $testRows += [PSCustomObject]@{
                example_id = [System.IO.Path]::GetFileNameWithoutExtension($destinationName)
                ground_truth_label = $class.Name
                original_file = $image.Name
            }
            $testNumber++
        } elseif ($index -lt 15) {
            $split = "validation"
            $destinationName = $image.Name
            $destinationDirectory = Join-Path $OutputRoot "validation\\$($class.Name)"
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
            Copy-Item -LiteralPath $image.FullName -Destination (Join-Path $destinationDirectory $destinationName)
        } else {
            $split = "train"
            $destinationName = $image.Name
            $destinationDirectory = Join-Path $OutputRoot "train\\$($class.Name)"
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
            Copy-Item -LiteralPath $image.FullName -Destination (Join-Path $destinationDirectory $destinationName)
        }

        $allRows += [PSCustomObject]@{
            split = $split
            label = $class.Name
            original_file = $image.Name
            output_file = $destinationName
        }
    }
}

$metadata = Join-Path $OutputRoot "metadata"
$allRows | Export-Csv -LiteralPath (Join-Path $metadata "split_manifest.csv") -NoTypeInformation
$testRows | Export-Csv -LiteralPath (Join-Path $metadata "test_labels_private.csv") -NoTypeInformation

$headers = "example_id,human_prediction,notes"
Set-Content -LiteralPath (Join-Path $metadata "human_predictions_yuxiang.csv") -Value $headers
Set-Content -LiteralPath (Join-Path $metadata "human_predictions_ivans.csv") -Value $headers

Write-Host "Created fixed FMD split at $OutputRoot"
Write-Host "Train: 850 images; validation: 100 images; blind test: 50 images."
