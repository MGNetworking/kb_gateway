# Spring Cloud Gateway API

Une API Gateway basée sur Spring Cloud Gateway pour le load balancing et le routage des microservices, containerisée et
déployable sur Kubernetes.

## Table des matières

* [Prérequis](#prérequis)
* [Scripts d'automatisation](#scripts-dautomatisation)
* [Configuration locale](#configuration-locale)
* [Développement avec Docker](#développement-avec-docker)
* [Tests avec Minikube](#tests-avec-minikube)
* [Déploiement Kubernetes](#déploiement-kubernetes)
* [Configuration DNS locale](#configuration-dns-locale)
* [Comprendre Ingress vs Ingress Controller](#comprendre-ingress-vs-ingress-controller)
* [Dépannage](#dépannage)

## Scripts d'automatisation

Pour simplifier le développement, plusieurs scripts PowerShell sont disponibles pour automatiser les tâches courantes :

### build_docker.ps1

Script d'automatisation pour le build, tag et push d'images Docker.

**Fonctionnalités :**

- Vérification des prérequis (Docker installé et daemon en cours)
- Authentification automatique à Docker Hub
- Build de l'image Docker
- Tag pour le registre
- Push vers Docker Hub

**Utilisation :**

```powershell
# Exécution du script
.\build_docker.ps1

# Le script vous demandera vos identifiants Docker Hub si nécessaire
```

**Ce que fait le script :**

1. Vérifie que Docker est installé et fonctionnel
2. Gère l'authentification Docker Hub (demande les identifiants si nécessaire)
3. Construit l'image `api-gateway:latest`
4. Tag l'image pour `ghmaxime88/api-gateway:latest`
5. Pousse l'image vers Docker Hub

### deploy_k8s.ps1

Script d'automatisation pour le déploiement Kubernetes complet.

**Fonctionnalités :**

- Déploiement automatique des ressources Kubernetes
- Surveillance du statut des pods
- Affichage des logs en temps réel
- Vérifications de santé

**Utilisation :**

```powershell
# Exécution du script
.\deploy_k8s.ps1
```

**Ce que fait le script :**

1. Vérifie que kubectl est installé
2. Applique les fichiers YAML dans l'ordre correct :
   - `deployment.yaml`
   - `service.yaml`
   - `ingress.yaml`
3. Surveille le statut des ressources
4. Attend que les pods soient prêts (timeout 5 minutes)
5. Affiche les détails et logs des pods

### cleanup_k8s.ps1

Script de nettoyage pour supprimer les ressources Kubernetes et images Docker.

**Fonctionnalités :**

- Suppression complète des ressources Kubernetes
- Nettoyage des images Docker locales
- Gestion des erreurs gracieuse

**Utilisation :**

```powershell
# Exécution du script
.\cleanup_k8s.ps1
```

**Ce que fait le script :**

1. Supprime les déploiements Kubernetes
2. Supprime les services et ingress
3. Supprime les images Docker locales :
   - `api-gateway:latest`
   - `ghmaxime88/api-gateway:latest`
4. Affiche les résultats de chaque opération

### Workflow de développement avec les scripts

**Développement complet :**

```powershell
# 1. Build et publication
.\build_docker.ps1

# 2. Déploiement et tests
.\deploy_k8s.ps1

# 3. Nettoyage après tests
.\cleanup_k8s.ps1
```

**Développement itératif :**

```powershell
# Modification du code, puis :
.\cleanup_k8s.ps1    # Nettoyage rapide
.\build_docker.ps1    # Nouveau build
.\deploy_k8s.ps1      # Redéploiement
```

## Prérequis

- Java 17+
- Maven 3.6+
- Docker Desktop
- Minikube (pour les tests locaux)
- kubectl
- PowerShell 5.1+ (pour les scripts d'automatisation)
- Compte Docker Hub (pour la publication d'images)

### Configuration requise pour les scripts

**Activation de l'exécution de scripts :**

```powershell
# Si nécessaire, autoriser l'exécution des scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Configuration locale

### Démarrage en local

```shell
# Compilation et démarrage
mvn clean spring-boot:run

# Ou avec Maven wrapper
./mvnw clean spring-boot:run
```

### Test de la gateway

```shell
# Vérification du health check
curl http://localhost:8080/actuator/health

# Test des endpoints actuator
curl http://localhost:8080/actuator
```

## Développement avec Docker

### Construction de l'image

```shell
# Build du projet et création de l'image
./mvnw clean package -DskipTests
docker build -t api-gateway:latest .
```

### Exécution en local

```shell
# Démarrage en mode interactif
docker run --name api-gateway -p 8080:8080 api-gateway:latest

# Démarrage en mode détaché
docker run -d --name api-gateway -p 8080:8080 api-gateway:latest
```

### Gestion des conteneurs

```shell
# Voir les logs
docker logs -f api-gateway

# Démarrer/arrêter
docker start api-gateway
docker stop api-gateway

# Supprimer le conteneur et l'image
docker stop api-gateway && docker rm api-gateway
docker rmi api-gateway:latest

# Nettoyer les images non utilisées
docker image prune
```

### Publication sur Docker Hub

```shell
# Méthode manuelle
docker login
docker tag api-gateway:latest ghmaxime88/api-gateway:latest
docker push ghmaxime88/api-gateway:latest
docker pull ghmaxime88/api-gateway:latest
```

**Ou utiliser le script automatisé :**

```powershell
.\build_docker.ps1
```

## Tests avec Minikube

### Démarrage de Minikube

Avec les droits administrateur uniquement ouvré un terminal Windows. Vous pourrez exécuter les commandes ci-dessous.

```shell
# Démarrage avec driver hyperv
minikube start --driver=hyperv

# Activation de l'addon Ingress
minikube addons enable ingress

# Configuration de l'environnement Docker pour Minikube
minikube -p minikube docker-env | Invoke-Expression

# Commande 
minikube start
minikube status
minikube stop
```

### Gestion des images dans Minikube

```shell
# Lister les images dans Minikube
minikube image ls

# Charger une image locale dans Minikube
minikube image load api-gateway:latest

# Supprimer une image de Minikube
minikube image rm api-gateway:latest
```

### Déploiement rapide pour tests

```shell
# Méthode manuelle
kubectl apply -f ./k8s/rbac-dev.yaml
kubectl apply -f ./k8s/deployment.yaml
kubectl apply -f ./k8s/service.yaml
kubectl apply -f ./k8s/ingress.yaml

# Vérifier le déploiement
kubectl get pods
kubectl get services
kubectl get ingress
```

**Ou utiliser le script automatisé :**

```powershell
.\deploy_k8s.ps1
```

### Tests dans Minikube

```shell
# Test direct via l'IP Minikube
curl -v http://$(minikube ip):30080/actuator/health

# Port-forward pour tests locaux
kubectl port-forward svc/api-gateway 8777:8080

# Test via port-forward
curl http://localhost:8777/actuator/health
```

## Déploiement Kubernetes

### Ordre de déploiement

Les fichiers doivent être appliqués dans cet ordre :

```shell
# 1. Permissions RBAC
kubectl apply -f ./k8s/rbac-dev.yaml

# 2. Déploiement de l'application
kubectl apply -f ./k8s/deployment.yaml

# 3. Service pour l'exposition interne
kubectl apply -f ./k8s/service.yaml

# 4. Ingress pour l'exposition externe
kubectl apply -f ./k8s/ingress.yaml

# 5. Optionnel : ConfigMap et Secrets
kubectl apply -f ./k8s/configmap.yaml
kubectl apply -f ./k8s/secret.yaml
```

### Vérifications du déploiement

```shell
# Vue d'ensemble
kubectl get all

# Vérification des pods
kubectl get pods -l app=api-gateway

# Vérification des services
kubectl get svc

# Vérification des ingress
kubectl get ingress

# Vérification des endpoints
kubectl get endpoints api-gateway

# Logs de l'application
kubectl logs -l app=api-gateway
kubectl logs -f <nom-du-pod>
```

### Diagnostic

```shell
# Détails d'un pod
kubectl describe pod <nom-du-pod>

# Détails de l'ingress
kubectl describe ingress api-gateway-ingress

# Variables d'environnement dans un pod
kubectl exec -it <nom-du-pod> -- env

# Vérification des permissions RBAC
kubectl get clusterrolebinding gateway-discovery-binding -o yaml
```

### Nettoyage

```shell
# Méthode manuelle
kubectl delete deployment api-gateway
kubectl delete service api-gateway
kubectl delete ingress api-gateway-ingress

# Supprimer les ressources RBAC (optionnel)
kubectl delete serviceaccount gateway-sa
kubectl delete clusterrole spring-k8s-discovery
kubectl delete clusterrolebinding gateway-discovery-binding

# Supprimer toutes les ressources d'un namespace
kubectl delete all --all -n default
```

**Ou utiliser le script automatisé :**

```powershell
.\cleanup_k8s.ps1
```

## Configuration DNS locale

### Fichier hosts pour Minikube

Pour accéder à l'application via un nom de domaine en local, ajoutez l'entrée suivante dans votre fichier hosts :

**Windows :** `C:\Windows\System32\drivers\etc\hosts`
**Linux/macOS :** `/etc/hosts`

```
# Obtenir l'IP de Minikube
minikube ip

# Ajouter dans le fichier hosts (remplacer <MINIKUBE_IP> par l'IP obtenue)
<MINIKUBE_IP> gateway.local
```

### Test avec le nom de domaine

```shell
# Après configuration du fichier hosts
curl http://gateway.local/actuator/health
```

## Comprendre Ingress vs Ingress Controller

### Distinction importante

Dans Kubernetes, il existe **deux composants distincts** pour la gestion du trafic externe :

#### 1. Votre ressource Ingress (`api-gateway-ingress`)
- **Fichier** : `./k8s/ingress.yaml`
- **Namespace** : `default` (votre application)
- **Rôle** : Définit les **règles de routage** (quelle URL va vers quel service)
- **Nature** : Configuration déclarative

**Exemple** :
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-gateway-ingress
  namespace: default
spec:
  rules:
  - host: gateway.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 8080
```

#### 2. L'Ingress Controller (`ingress-nginx-controller`)
- **Namespace** : `ingress-nginx` (composant système)
- **Rôle** : **Implémente** les règles définies dans vos ressources Ingress
- **Nature** : Application qui fait le travail réel de routage du trafic
- **Installation** : Automatique avec `minikube addons enable ingress`

### Analogie
- **Votre fichier Ingress** = Le plan/la recette de cuisine
- **L'Ingress Controller** = Le chef qui exécute la recette

### Vérification de la configuration

```shell
# Voir votre ressource Ingress (la configuration)
kubectl get ingress api-gateway-ingress
kubectl describe ingress api-gateway-ingress

# Voir l'Ingress Controller (le moteur d'exécution)
kubectl get pods -n ingress-nginx
kubectl describe pod -n ingress-nginx <nom-du-pod-controller>
```

### Diagnostic des problèmes

Si votre application n'est pas accessible via l'Ingress :

1. **Vérifier votre configuration Ingress** :
```shell
kubectl describe ingress api-gateway-ingress
```

2. **Vérifier que l'Ingress Controller fonctionne** :
```shell
kubectl get pods -n ingress-nginx
```

3. **Consulter les logs de l'Ingress Controller** :
```shell
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Pourquoi deux composants ?

Cette séparation permet :
- **Flexibilité** : Vous pouvez changer d'Ingress Controller (NGINX, Traefik, HAProxy) sans changer vos règles
- **Réutilisabilité** : Un seul Ingress Controller peut gérer plusieurs ressources Ingress
- **Maintenance** : Le Controller est géré par l'équipe infrastructure, les règles par les équipes applicatives

## Dépannage

### Vérifications communes

```shell
# Vérifier le contexte kubectl
kubectl config current-context

# Vérifier les nœuds
kubectl get nodes

# Vérifier les événements
kubectl get events --sort-by=.metadata.creationTimestamp

# Vérifier l'addon Ingress dans Minikube
kubectl get pods -n ingress-nginx
```

### Problèmes fréquents

- **Image non trouvée** : Vérifiez que l'image est bien chargée dans Minikube avec `minikube image ls`
- **Service inaccessible** : Vérifiez que le service est bien associé à un pod avec `kubectl get endpoints`
- **Ingress non fonctionnel** : Vérifiez que l'addon ingress est activé avec `minikube addons list`
- **Routage ne fonctionne pas** : Vérifiez les logs de l'Ingress Controller avec `kubectl logs -n ingress-nginx deployment/ingress-nginx-controller`

### Logs utiles

```shell
# Logs du pod applicatif
kubectl logs -f [nom-du-pod]

# Logs de l'ingress controller (pour diagnostic du routage)
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Événements en temps réel
kubectl get events --watch
```

## Architecture des fichiers

- **deployment.yaml** : Définit comment déployer l'application (replicas, image, variables)
- **service.yaml** : Expose l'application en interne (ClusterIP, NodePort, LoadBalancer)
- **ingress.yaml** : Route les requêtes HTTP externes vers le Service
- **rbac-dev.yaml** : Définit les permissions pour la découverte de services Kubernetes