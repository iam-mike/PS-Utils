# CommitChanges.ps1
# Copyright © 2009 Microsoft Corporation

# This script applies the changes necessary to migrate configuration.

$changes_filename = 'changes.xml'
$undone_filename = 'undone.xml'

$imports = ConvertTo-FIMResource -file $changes_filename
if ($null -eq $imports) {
    throw (New-Object NullReferenceException -ArgumentList 'Changes is null.  Check that the changes file has data.')
}
Write-Host 'Importing changes into production.'
$undoneImports = $imports | Import-FIMConfig
if ($null -eq $undoneImports) {
    Write-Host 'Import complete.'
}
else {
    Write-Host
    Write-Host 'There were ' $undoneImports.Count ' uncompleted imports.'
    $undoneImports | ConvertFrom-FIMResource -file $undone_filename
    Write-Host
    Write-Host 'Please see the documentation on how to resolve the issues.'
}
