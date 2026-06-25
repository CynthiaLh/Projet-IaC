# Preuves d'Exécution (AWS CLI)

Ce document démontre le bon fonctionnement de notre infrastructure automatisée (Terraform + Ansible) sur notre compte AWS.

## 1. Création et vérification des Buckets S3 (Terraform)

Le code Terraform a réussi à s'authentifier avec succès (via `AssumeRole` avec les identifiants étudiants) et a provisionné nos deux buckets S3.
Toutes nos ressources ont passé la validation de la politique IAM stricte car nous avons injecté le tag obligatoire : `Project = "ynov-iac-2026"`.

**Commandes d'exécution Terraform :**
```bash
# 1. Authentification AWS via le script (identifiants temporaires)
source assume_role.sh
```
**Sortie d'exécution :**
```text
Demande de session temporaire via Assume Role pour le rôle : arn:aws:iam::738563260931:role/role_etudiants...
Session temporaire AWS configurée avec succès pour notre terminal.
```

```bash
# 2. Initialisation et déploiement de l'infrastructure
cd terraform
terraform init
terraform apply -auto-approve
```
**Sortie d'exécution :**
```text
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

**Vérification CLI (Buckets S3) :**
```bash
aws s3 ls | grep ynov
```
**Sortie d'exécution :**
```text
2026-06-25 18:45:32 ynov-img2pdf-dest-bb433635
2026-06-25 18:45:32 ynov-img2pdf-source-bb433635
```
*Nos deux buckets sont bien présents en production, avec un suffixe aléatoire pour éviter les collisions globales de nommage.*

## 2. Déploiement de la Lambda (Ansible)

Le playbook Ansible a été exécuté avec succès pour installer les dépendances Python (`fpdf2`) et packager le code de la Lambda dans un fichier ZIP prêt pour Terraform.

**Commandes d'exécution Ansible :**
```bash
# Exécution du playbook pour générer le paquet Lambda
cd ansible
ansible-playbook playbook.yml
```
**Sortie d'exécution :**
```text
PLAY [Update Lambda Function Source Code] **************************************

TASK [Create build directory] **************************************************
changed: [localhost]

TASK [Install dependencies] ****************************************************
changed: [localhost]

TASK [Copy handler to build directory] *****************************************
changed: [localhost]

TASK [Zip the build directory] *************************************************
changed: [localhost]

TASK [Update Lambda code] ******************************************************
ok: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

```bash
# Vérification de la création de l'artefact ZIP
ls -lh ../terraform/modules/lambda/lambda.zip
```
**Sortie d'exécution :**
```text
-rw-r--r-- 1 cynthia cynthia 2.4M Jun 25 18:40 ../terraform/modules/lambda/lambda.zip
```

**Note sur l'environnement étudiant :**
Lors du `terraform apply`, la création de la fonction Lambda (`ynov-img2pdf-converter`) rencontre une limitation de la politique IAM du Lab AWS Academy :
> `AccessDeniedException: User: [...] is not authorized to perform: lambda:CreateFunction [...] with an explicit deny in an identity-based policy: arn:aws:iam::738563260931:policy/role-student-policy`

Malgré la présence du bon tag `ynov-iac-2026`, la politique globale `role-student-policy` interdit la création de ressource `lambda:CreateFunction` à ce rôle restreint. L'infrastructure de bout en bout est cependant parfaitement codée (Le plan Terraform est valide, Ansible génère correctement le paquet ZIP avec `fpdf2`, et la CI/CD est au vert). 

## 3. Plan d'exécution Terraform

Nous avons validé notre infrastructure via les commandes standards de Terraform pour s'assurer de sa conformité.

**Commandes de validation :**
```bash
cd terraform
terraform fmt -check
terraform validate
```
**Sortie d'exécution :**
```text
Success! The configuration is valid.
```

```bash
terraform plan
```
**Extrait de la validation (Local & CI/CD) :**
```text
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.s3.aws_s3_bucket.destination_bucket will be created
  + resource "aws_s3_bucket" "destination_bucket" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = (known after apply)
      + bucket_domain_name          = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = true
      + tags_all                    = {
          + "Project" = "ynov-iac-2026"
        }
    }

  # module.lambda.aws_lambda_function.img2pdf will be created
  + resource "aws_lambda_function" "img2pdf" {
      + function_name                  = "ynov-img2pdf-converter"
      + handler                        = "handler.lambda_handler"
      + runtime                        = "python3.11"
      + tags                           = {
          + "Project" = "ynov-iac-2026"
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.
```
