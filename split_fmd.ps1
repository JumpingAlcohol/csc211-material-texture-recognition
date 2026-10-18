param(
    [string]$SourceRoot = (Join-Path $PSScriptRoot "FMD"),
    [string]$OutputRoot = (Join-Path $PSScriptRoot "FMD_split")
)

# Fixed CSC211 scope: 85 training, 10 validation and 5 test pairs per class.
# For an existing split with human predictions, use add_validation_split.ps1 instead.
$classes = @("leather", "metal", "stone", "water", "wood")
$testPerClass = 5
$validationPerClass = 10

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
foreach ($path in @("train\\image", "train\\mask", "validation\\image", "validation\\mask", "test\\image", "test\\mask", "metadata")) {
    New-Item -ItemType Directory -Path (Join-Path $OutputRoot $path) | Out-Null
}

$allRows = @()
$testRows = @()

# Pick five deterministic examples per class, then randomize their anonymous test IDs
# across all classes. This prevents the test folder's filename order from revealing class blocks.
$testCandidates = @()
foreach ($class in $classes) {
    $imageDirectory = Join-Path $SourceRoot "image\\$class"
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

    $testCandidates += ($images | Select-Object -First $testPerClass | ForEach-Object {
        $orderBytes = [System.Security.Cryptography.SHA256]::HashData(
            [System.Text.Encoding]::UTF8.GetBytes("CSC211-FMD-five-class-test-order-v1|$class|$($_.File.Name)"))
        [PSCustomObject]@{
            Class = $class
            FileName = $_.File.Name
            OrderKey = [Convert]::ToHexString($orderBytes)
        }
    })
}

$testNameMap = @{}
$testNumber = 1
foreach ($candidate in ($testCandidates | Sort-Object OrderKey)) {
    $testNameMap["$($candidate.Class)|$($candidate.FileName)"] = "test_{0:D3}.jpg" -f $testNumber
    $testNumber++
}

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

        $testKey = "$class|$($image.Name)"
        if ($testNameMap.ContainsKey($testKey)) {
            $split = "test"
            $outputName = $testNameMap[$testKey]
            Copy-Item -LiteralPath $image.FullName -Destination (Join-Path $OutputRoot "test\\image\\$outputName")
            Copy-Item -LiteralPath $maskPath -Destination (Join-Path $OutputRoot "test\\mask\\$outputName")
            $testRows += [PSCustomObject]@{
                example_id = [System.IO.Path]::GetFileNameWithoutExtension($outputName)
                ground_truth_label = $class
                original_file = $image.Name
            }
        } else {
            $split = "train"
            if ($index -lt ($testPerClass + $validationPerClass)) {
                $split = "validation"
            }
            $outputName = $image.Name
            $trainImageDirectory = Join-Path $OutputRoot "$split\\image\\$class"
            $trainMaskDirectory = Join-Path $OutputRoot "$split\\mask\\$class"
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
$allRows | Export-Csv -LiteralPath (Join-Path $metadata "split_manifest.csv") -NoTypeInformation -UseQuotes Always
$testRows | Sort-Object example_id | Export-Csv -LiteralPath (Join-Path $metadata "test_labels_private.csv") -NoTypeInformation -UseQuotes Always
$humanTemplate = $testRows | Sort-Object example_id | Select-Object example_id, @{Name = "human_prediction"; Expression = { "" }}, @{Name = "notes"; Expression = { "" }}
$humanTemplate | Export-Csv -LiteralPath (Join-Path $metadata "human_predictions_yuxiang.csv") -NoTypeInformation -UseQuotes Always
$humanTemplate | Export-Csv -LiteralPath (Join-Path $metadata "human_predictions_ivans.csv") -NoTypeInformation -UseQuotes Always

Write-Host "Created fixed five-class FMD split at $OutputRoot"
Write-Host "Train: 425 pairs; validation: 50 pairs; test: 25 anonymous pairs."
