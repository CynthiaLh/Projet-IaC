# Projet : Infrastructure as Code — Terraform · Ansible · AWS

Ce projet met en place l'infrastructure demandée, qui comprend :
- Deux buckets S3 (source et destination).
- Une fonction Lambda qui convertit une image en PDF.
- Un déclencheur (trigger) S3 qui exécute la Lambda à l'upload d'une image dans le bucket source.
- Un playbook Ansible pour mettre à jour le code de la Lambda.
- Un pipeline CI/CD GitHub Actions effectuant des vérifications (fmt, validate, plan, Checkov, Infracost, ansible-lint).

> **Note** : Nous avons bien appliqué le tag obligatoire `Project = "ynov-iac-2026"` sur toutes nos ressources Terraform.

## Structure du Projet

- `terraform/` : Configuration Terraform avec les modules `s3` et `lambda`.
- `ansible/` : Playbook Ansible et code source définitif de la Lambda (`handler.py`).
- `.github/workflows/` : Pipeline CI/CD GitHub Actions.
- `ynov-student_accessKeys.csv` a été explicitement ignoré via le fichier `.gitignore` afin de ne jamais exposer nos identifiants sur GitHub.

## Déploiement

### 1. Terraform (Infrastructure initiale)

**Bonne pratique de sécurité :** Nos credentials (du fichier CSV) ne sont jamais inscrits en dur. Pour cela, nous avons créé un script qui lit le fichier `ynov-student_accessKeys.csv`, s'authentifie et stocke les credentials temporaires uniquement en mémoire (variables d'environnement de notre terminal).

Nous exécutons cette commande pour charger nos accès AWS temporaires dans notre terminal actuel :

```bash
source assume_role.sh
```

Ensuite, nous déployons notre infrastructure Terraform :

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Ansible (Mise à jour du code Lambda)

Notre playbook Ansible se charge d'installer les dépendances (ex: `fpdf2`), de packager le code, puis de mettre à jour notre Lambda.

```bash
cd ansible
ansible-playbook playbook.yml
```

### 3. Preuves d'exécution (AWS CLI)

Pour valider notre travail (upload et conversion) :

```bash
# Upload d'une image dans le bucket source
aws s3 cp image.jpg s3://ynov-img2pdf-source-<id>/

# Vérification de la création du fichier PDF dans le bucket de destination
aws s3 ls s3://ynov-img2pdf-dest-<id>/
```

### 4. GitHub Actions (CI/CD)

Le fichier `.github/workflows/terraform.yaml` inclut l'intégration et le déploiement continu.
**Règles de sécurité :** Nous n'avons ajouté **aucun secret** dans le code. Les accès à AWS et l'API Key pour Infracost sont configurés via les **GitHub Secrets** du dépôt :
1. Dans les **Settings** du dépôt > **Secrets and variables** > **Actions**.
2. Nous avons défini les secrets suivants :
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `INFRACOST_API_KEY` (Optionnel mais recommandé pour le calcul des coûts)
