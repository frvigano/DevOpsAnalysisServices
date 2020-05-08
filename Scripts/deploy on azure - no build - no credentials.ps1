## DEPLOY ENVIRONMENT CONFIGURATION
## ASSUME BUILD done with VISUAL STUDIO


# install SqlServer cmdlets by executing
# Install-module -AllowClobber -Name SqlServer

#dove scarico i file della solution
$dir = "C:\Temp\SalesAnalysis2019Azure\SalesAnalysis2019\"

#solution name
$solution = "SalesAnalysis2019.smproj"

#DEPLOYMENT SETTINGS
#nome del database una volta deployato su AAS
$database = "SalesAnalysis2019"
#server AAS
$server ="asazure://westcentralus.asazure.windows.net/fviaas"

# AZURE SERVICE PRINCIPAL
# if you do not have one, create a Service principal
# https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#create-an-azure-active-directory-application

# application id taken from Azure Active Directory
# https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#get-values-for-signing-in
$tenant =""
$application =""

# get secret following documentation
# https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#create-a-new-application-secret
$secret = ""

#Add the application as AAS instance admin in the form app:application@tenand

#idenfifier
$identifier = "app:"+$application


#CONNECTIONS SETTINGS
#static example. Read from secure keyvault
$password = ""

#CONNECTION FILE
$connectionfile = "connection.json"
$connectionfile = $dir +$connectionfile

#build file
$bin = $dir +"bin\"
$model = $bin + "Model.asdatabase"

$secret = ConvertTo-SecureString $secret -AsPlainText -Force        


#read build output and create TMSL to deploy 
$modeljson = gc $model -raw | ConvertFrom-Json
$tmsl = '{"createOrReplace":{"object":{"database":""},"database":{}}}' | ConvertFrom-Json
$($tmsl.createOrReplace.object).database = $database
$($tmsl.createOrReplace).database = $modeljson

#manage connections
#configuration file with REPLACE. You can manipulate the JSON directly 
$connections = Get-Content $connectionfile -Raw 
$connections = $connections.Replace("#PASSWORD#",$password)


#credentials to interact with AAS
$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $identifier, $secret

#deploy model
Invoke-ASCmd -Query ($tmsl | ConvertTo-Json -Depth 25)  -Server $server -Credential $credentials -TenantId $tenant

#deploy connections
Invoke-ASCmd -Query $connections  -Server $server -Credential $credentials -TenantId $tenant
 
#process 
Invoke-ProcessASDatabase -Server $server -Credential $credentials -TenantId $tenant -DatabaseName $database  -RefreshType "Full"
