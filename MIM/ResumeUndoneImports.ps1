# ResumeUndoneImports.ps1
# Copyright © 2010 Microsoft Corporation

# This script resumes incomplete imports once the specific error has been identified.

# It may be necessary to edit the first ImportObject in the undone imports file.
# Some changes include removing the object altogether or removing a particular attribute value.
$undone_filename = 'undone.xml'

$undoneImports = ConvertTo-FIMResource -file $undone_filename
if ($null -eq $undoneImports) {
    throw (New-Object NullReferenceException -ArgumentList 'Changes is null.  Check that the undone file has data.')
}
Write-Host 'Resuming import'
$newUndoneImports = $undoneImports | Import-FIMConfig

if ($null -eq $newUndoneImports) {
    Write-Host 'Import complete.'
}
else {
    Write-Host
    Write-Host 'There were ' $newUndoneImports.Count ' uncompleted imports.'
    $newUndoneImports | ConvertFrom-FIMResource -file $undone_filename
    Write-Host
    Write-Host 'Please see the documentation on how to resolve the issues.'
}
