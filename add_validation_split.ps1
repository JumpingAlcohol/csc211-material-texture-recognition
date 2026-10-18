# Migrate the existing 95/5 split without rewriting test files or human predictions.
[CmdletBinding()]
param([string]$SplitRoot = (Join-Path $PSScriptRoot 'FMD_split'))

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $SplitRoot).Path
$classes = @('leather', 'metal', 'stone', 'water', 'wood')
$manifestPath = Join-Path $root 'metadata/split_manifest.csv'
$rows = @(Import-Csv -LiteralPath $manifestPath)
if ($rows.Count -ne 500 -or (Test-Path -LiteralPath (Join-Path $root 'validation'))) {
    throw 'Expected the original 500-example train/test split with no validation directory.'
}

# Snapshot bytes of the complete test set, label mapping, and all human worksheets.
$protected = @(Get-ChildItem -LiteralPath (Join-Path $root 'test') -Recurse -File)
$protected += Get-Item -LiteralPath (Join-Path $root 'metadata/test_labels_private.csv')
$protected += Get-ChildItem -LiteralPath (Join-Path $root 'metadata') -Filter 'human_predictions*.csv' -File
$before = @{}
foreach ($file in $protected) { $before[$file.FullName] = (Get-FileHash -LiteralPath $file.FullName).Hash }

# Validate every proposed move before changing anything. Only existing train pairs move.
$plan = @()
foreach ($class in $classes) {
    $training = @($rows | Where-Object { $_.label -eq $class -and $_.split -eq 'train' })
    $testing = @($rows | Where-Object { $_.label -eq $class -and $_.split -eq 'test' })
    if ($training.Count -ne 95 -or $testing.Count -ne 5) { throw "Unexpected split for $class" }
    $ranked = @($training | ForEach-Object {
        $bytes = [System.Security.Cryptography.SHA256]::HashData(
            [System.Text.Encoding]::UTF8.GetBytes("CSC211-FMD-five-class-v1|$class|$($_.original_file)"))
        [PSCustomObject]@{ Row = $_; Key = [Convert]::ToHexString($bytes) }
    } | Sort-Object Key | Select-Object -First 10)
    foreach ($item in $ranked) {
        foreach ($kind in @('image', 'mask')) {
            $name = $item.Row.output_file
            if ([IO.Path]::GetFileName($name) -ne $name) { throw 'Invalid filename in manifest.' }
            $source = (Resolve-Path -LiteralPath (Join-Path $root "train/$kind/$class/$name")).Path
            $destination = [IO.Path]::GetFullPath((Join-Path $root "validation/$kind/$class/$name"))
            if (-not $source.StartsWith($root + [IO.Path]::DirectorySeparatorChar) -or
                -not $destination.StartsWith($root + [IO.Path]::DirectorySeparatorChar)) {
                throw 'Move would leave the split directory.'
            }
            $plan += [PSCustomObject]@{ Source=$source; Destination=$destination; Row=$item.Row }
        }
    }
}

# Retain a recoverable manifest beside the repository, without publishing it.
$backup = Join-Path ([IO.Path]::GetTempPath()) ('csc211-validation-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $backup | Out-Null
Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $backup 'split_manifest.csv')
foreach ($move in $plan) {
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($move.Destination)) -Force | Out-Null
    Move-Item -LiteralPath $move.Source -Destination $move.Destination
    $move.Row.split = 'validation'
}
$rows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -UseQuotes Always -Encoding utf8
foreach ($file in $protected) {
    if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne $before[$file.FullName]) {
        throw "Protected file changed: $($file.Name)"
    }
}
Write-Output 'Moved 50 image/mask pairs from train to validation. Test and human predictions are byte-for-byte unchanged.'
Write-Output "Previous manifest backup: $backup"
