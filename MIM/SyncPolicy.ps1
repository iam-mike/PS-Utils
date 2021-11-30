# SyncPolicy.ps1
# Copyright © 2009 Microsoft Corporation

# The purpose of this script is to identify what changes should be applied to 
# the production environment.

# This script assumes that the production environment is the local machine and
# that the pilot export is available in pilot_policy.xml
# and the production export is available in production_policy.xml

$pilot_filename = 'pilot_policy.xml'
$production_filename = 'production_policy.xml'
$changes_filename = 'changes.xml'
$joinrules = @{
    # === Customer-dependent join rules ===
    # Person and Group objects are not configuration will not be migrated.
    # However, some configuration objects like Sets may refer to these objects.
    # For this reason, we need to know how to join Person objects between
    # systems so that configuration objects have the same semantic meaning.
    Person                           = 'MailNickname DisplayName';
    Group                            = 'DisplayName';
    
    # === Policy configuration ===
    # Sets, MPRs, Workflow Definitions, and so on. are best identified by DisplayName
    # DisplayName is set as the default join criteria and applied to all object
    # types not listed here.
    
    # === Schema configuration ===
    # This is based on the system names of attributes and objects
    # Notice that BindingDescription is joined using its reference attributes.
    ObjectTypeDescription            = 'Name';
    AttributeTypeDescription         = 'Name';
    BindingDescription               = 'BoundObjectType BoundAttributeType';
    
    # === Portal configuration ===
    ConstantSpecifier                = 'BoundObjectType BoundAttributeType ConstantValueKey';
    SearchScopeConfiguration         = 'DisplayName SearchScopeResultObjectType Order';
    ObjectVisualizationConfiguration = 'DisplayName AppliesToCreate AppliesToEdit AppliesToView'
}

if (@(get-pssnapin | Where-Object { $_.Name -eq 'FIMAutomation' } ).count -eq 0) { add-pssnapin FIMAutomation }

Write-Host 'Loading production file ' $production_filename '.'
$production = ConvertTo-FIMResource -file $production_filename
if ($null -eq $production) {
    throw (New-Object NullReferenceException -ArgumentList 'Production Schema is null.  Check that the production file has data.')
}

Write-Host 'Loaded file ' $production_filename '.' $production.Count ' objects loaded.'

Write-Host 'Loading pilot file ' $pilot_filename '.'
$pilot = ConvertTo-FIMResource -file $pilot_filename
if ($null -eq $pilot) {
    throw (New-Object NullReferenceException -ArgumentList 'Pilot Schema is null.  Check that the pilot file has data.')
}

Write-Host 'Loaded file ' $pilot_filename '.' $pilot.Count ' objects loaded.'
Write-Host
Write-Host 'Executing join between pilot and production.'
Write-Host 
$objectMatches = Join-FIMConfig -source $pilot -target $production -join $joinrules -defaultJoin DisplayName
if ($null -eq $objectMatches) {
    throw (New-Object NullReferenceException -ArgumentList 'Matches is null.  Check that the join succeeded and join criteria is correct for your environment.')
}
Write-Host 'Executing compare between matched objects in pilot and production.'
$changes = $objectMatches | Compare-FIMConfig
if ($null -eq $changes) {
    throw (New-Object NullReferenceException -ArgumentList 'Changes is null.  Check that no errors occurred while generating changes.')
}
Write-Host 'Identified ' $changes.Count ' changes to apply to production.'
Write-Host 'Saving changes to ' $changes_filename '.'
$changes | ConvertFrom-FIMResource -file $changes_filename
Write-Host
Write-Host 'Sync complete. The next step is to commit the changes using CommitChanges.ps1.'
