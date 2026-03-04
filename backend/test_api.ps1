$body = @{
    usernameOrEmail = "admin"
    password = "password"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:8081/api/auth/signin" -Method Post -Body $body -ContentType "application/json" -ErrorAction SilentlyContinue

if ($null -eq $response) {
    Write-Host "Failed to login as admin, trying fongyisa"
    $body = @{
        usernameOrEmail = "fongyisa"
        password = "password"
    } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "http://localhost:8081/api/auth/signin" -Method Post -Body $body -ContentType "application/json"
}

$token = $response.accessToken
Write-Host "Token: $token"

$headers = @{ Authorization = "Bearer $token" }

try {
    $res = Invoke-RestMethod -Uri "http://localhost:8081/api/users" -Headers $headers -Method Get
    Write-Host "Success!"
    $res | ConvertTo-Json -Depth 2
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $errorBody = $reader.ReadToEnd()
    Write-Host "Response Body: $errorBody"
}
