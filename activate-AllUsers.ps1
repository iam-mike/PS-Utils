$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Accept", "application/json")
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "SSWS 00P8-6KQzwH8bCMe0eYUlq0p9fq_TroCVk6rqpXaO-")

$users = Invoke-RestMethod 'https://mw-classic.oktapreview.com/api/v1/groups/00g3n1ihe93uxWave1d7/users' -Method 'GET' -Headers $headers

$body = ""

foreach ($user in $users) {
    $id = $user.id
    Write-Host "activating $id"
    Invoke-RestMethod "https://mw-classic.oktapreview.com/api/v1/users/$id/lifecycle/activate?sendEmail=false" -Method 'POST' -Headers $headers -Body $body
}