# Script PowerShell pour automatiser le build, tag et push d'une image Docker pour api-gateway

# Forcer l'encodage UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# Fonction pour vérifier si une commande existe
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Vérifier si Docker est installé
Write-Host "Vérification de l'installation de Docker..."
if (-not (Test-CommandExists docker)) {
    Write-Error "Docker n'est pas installé ou n'est pas dans le PATH. Veuillez installer Docker Desktop."
    exit 1
}

# Vérifier si Docker daemon est en cours d'exécution
Write-Host "Vérification du Docker daemon..."
try {
    docker info | Out-Null
}
catch {
    Write-Error "Le Docker daemon n'est pas en cours d'exécution. Veuillez démarrer Docker Desktop."
    exit 1
}

# Vérifier si l'utilisateur est connecté à Docker Hub
Write-Host "Vérification de la connexion à Docker Hub..."
$dockerLoginStatus = docker system info --format '{{.DockerConfig.RegistryAuth}}'

if (-not $dockerLoginStatus) {
    Write-Host "Aucune connexion active détectée. Veuillez vous connecter à Docker Hub."
    $username = Read-Host "Entrez votre nom d'utilisateur Docker Hub"
    $password = Read-Host "Entrez votre mot de passe Docker Hub" -AsSecureString
    $passwordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    )

    Write-Host "Connexion à Docker Hub..."
    try {
        echo $passwordPlain | docker login --username $username --password-stdin
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Échec de la connexion à Docker Hub."
            exit 1
        }
        Write-Host "Connexion réussie à Docker Hub."
    }
    catch {
        Write-Error "Erreur lors de la connexion à Docker Hub: $_"
        exit 1
    }
}
else {
    Write-Host "Déjà connecté à Docker Hub."
}

# Variables pour l'image
$imageName = "api-gateway"
$tag = "latest"
$registry = "ghmaxime88"

# Étape 1 : Build de l'image Docker
Write-Host "Construction de l'image Docker (${imageName}:${tag})..."
try {
    docker build -t "${imageName}:${tag}" .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Échec du build de l'image Docker."
        exit 1
    }
    Write-Host "Image Docker construite avec succès."
}
catch {
    Write-Error "Erreur lors du build de l'image Docker: $_"
    exit 1
}

# Étape 2 : Tag de l'image
Write-Host "Taggage de l'image pour le registre (${registry}/${imageName}:${tag})..."
try {
    docker tag "${imageName}:${tag}" "${registry}/${imageName}:${tag}"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Échec du taggage de l'image."
        exit 1
    }
    Write-Host "Image tagguée avec succès."
}
catch {
    Write-Error "Erreur lors du taggage de l'image: $_"
    exit 1
}

# Étape 3 : Push de l'image vers Docker Hub
Write-Host "Push de l'image vers Docker Hub (${registry}/${imageName}:${tag})..."
try {
    docker push "${registry}/${imageName}:${tag}"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Échec du push de l'image vers Docker Hub."
        exit 1
    }
    Write-Host "Image pushée avec succès vers Docker Hub."
}
catch {
    Write-Error "Erreur lors du push de l'image: $_"
    exit 1
}

Write-Host "Toutes les opérations ont été complétées avec succès!" -ForegroundColor Green