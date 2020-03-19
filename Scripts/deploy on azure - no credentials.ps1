## BUILD and DEPLOY ENVIRONMENT CONFIGURATION

# install MSBUIL

# install SqlServer cmdlets by executing
# Install-module -AllowClobber -Name SqlServer

#msbuild 
$msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\msbuild.exe"
#dove scarico i file della solution
$dir = "C:\Temp\SalesAnalysis2019Azure\SalesAnalysis2019\"
#solution name
$solution = "SalesAnalysis2019.smproj"

#DEPLOYMENT SETTINGS

#static example. Better to read from secure keyvault

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

#CONNECTIONS SETTINGS
# password of the database specified in the connection file. 
$password = ""

#CONNECTION FILE
$connectionfile = "connection.json"
$connectionfile = $dir +$connectionfile


##### BUILD AND DEPLOY 

## DEFINE SOME SUPPORT VARIABILES
#idenfifier
$identifier = "app:"+$application

#solution
$solution = $dir + $solution

#store build results
$bin = $dir +"bin\"
$model = $bin + "Model.asdatabase"

$secret = ConvertTo-SecureString $secret -AsPlainText -Force        


## BUILD
#read build output and create TMSL to deploy 
& $msbuild $solution
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
