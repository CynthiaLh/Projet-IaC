# Projet : Infrastructure as Code — Terraform · Ansible · AWS

Ce projet contient l'infrastructure demandée consistant en :
- Deux buckets S3 (source et destination).
- Une fonction Lambda qui convertit une image en PDF.
- Un déclencheur (trigger) S3 qui exécute la Lambda à l'upload d'une image dans le bucket source.
- Un playbook Ansible pour mettre à jour le code de la Lambda.
- Un pipeline CI/CD GitHub Actions effectuant des vérifications (fmt, validate, plan, Checkov, Infracost, ansible-lint).

> **Note** : Le tag obligatoire `Project = "ynov-iac-2026"` a bien été appliqué sur toutes les ressources Terraform.

## Structure du Projet

- `terraform/` : Configuration Terraform avec les modules `s3` et `lambda`.
- `ansible/` : Playbook Ansible et code source définitif de la Lambda (`handler.py`).
- `.github/workflows/` : Pipeline CI/CD GitHub Actions.
- `ynov-student_accessKeys.csv` a été explicitement ignoré via le fichier `.gitignore` afin de ne jamais l'exposer sur GitHub.

## Déploiement

### 1. Terraform (Infrastructure initiale)

Configurer les credentials AWS avec l'Assume Role, puis :

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Ansible (Mise à jour du code Lambda)

Le playbook Ansible installe les dépendances (ex: `fpdf2`), package le code, puis met à jour la Lambda.

```bash
cd ansible
ansible-playbook playbook.yml
```

### 3. Preuves d'exécution (AWS CLI)

Pour vérifier l'upload et la conversion (après déploiement) :

```bash
# Upload d'une image dans le bucket source
aws s3 cp image.jpg s3://ynov-img2pdf-source-<id>/

# Vérification de la création du fichier PDF dans le bucket de destination
aws s3 ls s3://ynov-img2pdf-dest-<id>/
```
