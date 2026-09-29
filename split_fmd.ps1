param(
    [string]$SourceRoot = (Join-Path $PSScriptRoot "FMD"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "FMD_split")
)

# Fixed CSC211 project scope: five material classes, 95 training and 5 test images per class.
$classes = @("leather", "metal", "stone", "water", "wood")
$testPerClass = 5

if (Test-Path -LiteralPath $OutputRoot) {
    throw "Output folder already exists: $OutputRoot. Refusing to overwrite an existing split."
}

foreach ($class in $classes) {
    foreach ($kind in @("image", "mask")) {
        $classPath = Join-Path $SourceRoot "$kind\\$class"
        if (-not (Test-Path -LiteralPath $classPath)) {
            throw "Missing source folder: $classPath"
        }
    }
}

New-Item -ItemType Directory -Path $OutputRoot | Out-Null
foreach ($path in @("train\\image", "train\\mask", "test\\image", "test\\mask", "metadata")) {
    New-Item -ItemType Directory -Path (Join-Path $OutputRoot $path) | Out-Null
}

$allRows = @()
$testRows = @()
$testNumber = 1

foreach ($class in $classes) {
    $imageDirectory = Join-Path $SourceRoot "image\\$class"
    $maskDirectory = Join-Path $SourceRoot "mask\\$class"
    $images = Get-ChildItem -LiteralPath $imageDirectory -File -Filter "*.jpg" |
        ForEach-Object {
            $hashBytes = [System.Security.Cryptography.SHA256]::HashData(
                [System.Text.Encoding]::UTF8.GetBytes("CSC211-FMD-five-class-v1|$class|$($_.Name)"))
            [PSCustomObject]@{ File = $_; SortKey = [Convert]::ToHexString($hashBytes) }
        } |
        Sort-Object SortKey

    if ($images.Count -ne 100) {
        throw "Expected 100 images for $class; found $($images.Count)."
    }

    foreach ($item in $images) {
        $maskPath = Join-Path $maskDirectory $item.File.Name
        if (-not (Test-Path -LiteralPath $maskPath)) {
            throw "Missing mask for image: $($item.File.Name)"
        }
    }

    for ($index = 0; $index -lt $images.Count; $index++) {
        $image = $images[$index].File
        $maskPath = Join-Path $maskDirectory $image.Name

        if ($index -lt $testPerClass) {
            $split = "test"
            $outputName = "test_{0:D3}.jpg" -f $testNumber
            Copy-Item -LiteralPath $image.FullName -Destination (Join-Path $OutputRoot "test\\image\\$outputName")
            Copy-Item -LiteralPath $maskPath -Destination (Join-Path $OutputRoot "test\\mask\\$outputName")
            $testRows += [PSCustomObject]@{
                example_id = [System.IO.Path]::GetFileNameWithoutExtension($outputName)
                ground_truth_label = $class
                original_file = $image.Name
            }
            $testNumber++
        } else {
            $split = "train"
            $outputName = $image.Name
            $trainImageDirectory = Join-Path $OutputRoot "train\\image\\$class"
            $trainMaskDirectory = Join-Path $OutputRoot "train\\mask\\$class"
            New-Item -ItemType Directory -Path $trainImageDirectory -Force | Out-Null
            New-Item -ItemType Directory -Path $trainMaskDirectory -Force | Out-Null
            Copy-Item -LiteralPath $image.FullName -Destination (Join-Path $trainImageDirectory $outputName)
            Copy-Item -LiteralPath $maskPath -Destination (Join-Path $trainMaskDirectory $outputName)
        }

        $allRows += [PSCustomObject]@{
            split = $split
            label = $class
            original_file = $image.Name
            output_file = $outputName
        }
    }
}

$metadata = Join-Path $OutputRoot "metadata"
$allRows | Export-Csv -LiteralPath (Join-Path $metadata "split_manifest.csv") -NoTypeInformation
$testRows | Export-Csv -LiteralPath (Join-Path $metadata "test_labels_private.csv") -NoTypeInformation
$humanTemplate = $testRows | Select-Object example_id, @{Name = "human_prediction"; Expression = { "" }}, @{Name = "notes"; Expression = { "" }}
$humanTemplate | Export-Csv -LiteralPath (Join-Path $metadata "human_predictions_yuxiang.csv") -NoTypeInformation
$humanTemplate | Export-Csv -LiteralPath (Join-Path $metadata "human_predictions_ivans.csv") -NoTypeInformation

Write-Host "Created fixed five-class FMD split at $OutputRoot"
Write-Host "Train: 475 image/mask pairs; test: 25 anonymous image/mask pairs."
