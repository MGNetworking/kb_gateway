# Script PowerShell pour supprimer les ressources Kubernetes et les images Docker pour api-gateway

# Forcer l'encodage UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# Fonction pour verifier si une commande existe
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Verifier si kubectl est installe
Write-Host "Verification de l'installation de kubectl..."
if (-not (Test-CommandExists kubectl)) {
    Write-Error "kubectl n'est pas installe ou n'est pas dans le PATH. Veuillez installer kubectl."
    exit 1
}

# Verifier si docker est installe
Write-Host "Verification de l'installation de Docker..."
if (-not (Test-CommandExists docker)) {
    Write-Error "Docker n'est pas installe ou n'est pas dans le PATH. Veuillez installer Docker Desktop."
    exit 1
}

# Verifier si les fichiers YAML existent
$yamlFiles = @("./k8s/deployment.yaml", "./k8s/service.yaml")
foreach ($file in $yamlFiles) {
    if (-not (Test-Path $file)) {
        Write-Error "Le fichier $file n'existe pas. Verifiez le chemin."
        exit 1
    }
}

# Etape 1 : Supprimer les ressources Kubernetes
Write-Host "Suppression des ressources Kubernetes..."
Write-Host "Suppression du deployment api-gateway..."
try {
    kubectl delete deployment api-gateway
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Echec de la suppression du deployment api-gateway. La ressource n'existe peut-etre pas."
    } else {
        Write-Host "Deployment api-gateway supprime avec succes."
    }
}
catch {
    Write-Warning "Erreur lors de la suppression du deployment : $_"
}

foreach ($file in $yamlFiles) {
    Write-Host "Suppression de $file..."
    try {
        kubectl delete -f $file
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Echec de la suppression du fichier $file. La ressource n'existe peut-etre pas."
        } else {
            Write-Host "Ressource definie dans $file supprimee avec succes."
        }
    }
    catch {
        Write-Warning "Erreur lors de la suppression du fichier $file : $_"
    }
}

# Supprimer l'ingress
Write-Host "Suppression de l'ingress api-gateway-ingress..."
try {
    kubectl delete -f ./k8s/ingress.yaml
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Echec de la suppression de l'ingress api-gateway-ingress. La ressource n'existe peut-etre pas."
    } else {
        Write-Host "Ingress api-gateway-ingress supprime avec succes."
    }
}
catch {
    Write-Warning "Erreur lors de la suppression de l'ingress : $_"
}

# Etape 2 : Supprimer les images Docker
$images = @("ghmaxime88/api-gateway:latest", "api-gateway:latest")
Write-Host "Suppression des images Docker..."
foreach ($image in $images) {
    Write-Host "Verification de l'existence de l'image $image..."
    try {
        $imageExists = docker images -q $image
        if ($imageExists) {
            Write-Host "Suppression de l'image $image..."
            docker rmi -f $image
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Echec de la suppression de l'image $image."
            } else {
                Write-Host "Image $image supprimee avec succes."
            }
        } else {
            Write-Host "L'image $image n'existe pas localement. Aucune suppression necessaire."
        }
    }
    catch {
        Write-Warning "Erreur lors de la suppression de l'image $image : $_"
    }
}

Write-Host "Toutes les operations de suppression ont ete completees!" -ForegroundColor Green