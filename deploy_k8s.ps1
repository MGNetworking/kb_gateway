# Script PowerShell pour automatiser le déploiement Kubernetes et l'inspection des ressources pour api-gateway

# Forcer l'encodage UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# Fonction pour vérifier si une commande existe
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Fonction pour attendre que le pod soit prêt
function Wait-PodRunning {
    param($podName)
    $timeoutSeconds = 300  # Temps d'attente maximal (5 minutes)
    $intervalSeconds = 10  # Intervalle entre les vérifications
    $elapsed = 0

    Write-Host "Attente que le pod $podName soit dans l'état Running..."
    while ($elapsed -lt $timeoutSeconds) {
        $status = kubectl get pod $podName -o jsonpath='{.status.phase}' --ignore-not-found
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Pod $podName non trouvé. Attente $intervalSeconds secondes..."
        }
        elseif ($status -eq "Running") {
            Write-Host "Pod $podName est dans l'état Running."
            return $true
        }
        else {
            Write-Host "Pod $podName est dans l'état $status. Attente $intervalSeconds secondes..."
        }
        Start-Sleep -Seconds $intervalSeconds
        $elapsed += $intervalSeconds
    }
    Write-Error "Le pod $podName n'est pas passé à l'état Running après $timeoutSeconds secondes."
    return $false
}

# Vérifier si kubectl est installé
Write-Host "Vérification de l'installation de kubectl..."
if (-not (Test-CommandExists kubectl)) {
    Write-Error "kubectl n'est pas installé ou n'est pas dans le PATH. Veuillez installer kubectl."
    exit 1
}

# Vérifier si les fichiers YAML existent
$yamlFiles = @("./k8s/deployment.yaml", "./k8s/service.yaml", "./k8s/ingress.yaml")
foreach ($file in $yamlFiles) {
    if (-not (Test-Path $file)) {
        Write-Error "Le fichier $file n'existe pas. Vérifiez le chemin."
        exit 1
    }
}

# Étape 1 : Appliquer les fichiers YAML
Write-Host "Application des fichiers YAML Kubernetes..."
foreach ($file in $yamlFiles) {
    Write-Host "Application de $file..."
    try {
        kubectl apply -f $file
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Échec de l'application du fichier $file."
            exit 1
        }
        Write-Host "Fichier $file appliqué avec succès."
    }
    catch {
        Write-Error "Erreur lors de l'application du fichier $file : $_"
        exit 1
    }
}

# Étape 2 : Récupérer les informations sur l'ingress
Write-Host "Récupération des informations sur l'ingress..."
try {
    kubectl get ingress
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Échec de la commande kubectl get ingress."
        exit 1
    }
}
catch {
    Write-Error "Erreur lors de la récupération des ingresses : $_"
    exit 1
}

# Étape 3 : Récupérer les informations sur les pods
Write-Host "Récupération des informations sur les pods..."
try {
    kubectl get pods
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Échec de la commande kubectl get pods."
        exit 1
    }
}
catch {
    Write-Error "Erreur lors de la récupération des pods : $_"
    exit 1
}

# Étape 4 : Récupérer le nom du pod associé au déploiement api-gateway
Write-Host "Récupération du nom du pod pour le déploiement api-gateway..."
try {
    $podName = kubectl get pods -l app=api-gateway -o jsonpath='{.items[0].metadata.name}' --ignore-not-found
    if (-not $podName) {
        Write-Error "Aucun pod trouvé pour le déploiement api-gateway ou erreur lors de la récupération du nom du pod."
        exit 1
    }
    Write-Host "Pod trouvé : $podName"
}
catch {
    Write-Error "Erreur lors de la récupération du nom du pod : $_"
    exit 1
}

# Étape 5 : Attendre que le pod soit prêt
if (-not (Wait-PodRunning -podName $podName)) {
    Write-Error "Le pod $podName n'est pas prêt. Arrêt du script."
    exit 1
}

# Étape 6 : Afficher les détails du pod
Write-Host "Affichage des détails du pod $podName..."
try {
    kubectl describe pod $podName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Échec de la commande kubectl describe pod $podName."
        exit 1
    }
}
catch {
    Write-Error "Erreur lors de l'affichage des détails du pod : $_"
    exit 1
}

# Étape 7 : Afficher les logs du pod en mode suivi
Write-Host "Affichage des logs du pod $podName (mode suivi)..."
try {
    kubectl logs -f $podName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Échec de la commande kubectl logs -f $podName."
        exit 1
    }
}
catch {
    Write-Error "Erreur lors de l'affichage des logs du pod : $_"
    exit 1
}

Write-Host "Toutes les opérations ont été complétées avec succès!" -ForegroundColor Green