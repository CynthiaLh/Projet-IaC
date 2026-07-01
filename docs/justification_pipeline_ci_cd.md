# Justification de l'Architecture de la Pipeline CI/CD

**Document de référence technique**

Ce document a pour objectif d'expliciter et de justifier l'ensemble des choix techniques effectués dans la conception de notre pipeline d'Intégration et de Déploiement Continus (CI/CD) sous GitHub Actions (`.github/workflows/terraform.yaml`). 

Il démontre la robustesse, la sécurité et la pertinence de nos méthodes de validation de l'Infrastructure as Code (IaC).

---

## 1. Présentation Générale de la Pipeline

### Objectif et Rôle de la CI/CD
Notre approche repose sur l'industrialisation des processus de validation. La pipeline agit comme une barrière de qualité, de sécurité et de viabilité financière *avant* toute application sur notre environnement AWS. L'utilisation de GitHub Actions permet d'intégrer nativement cette boucle de rétroaction au plus près du code source, directement déclenchée par des événements du cycle de vie du code (`push` et `pull_request` sur la branche `main`).

### Logique Générale et Dépendances
Le workflow (`terraform-and-ansible-checks`) s'articule autour d'une logique de type **Fail-Fast** : les contrôles les plus rapides et les plus bloquants (formatage, syntaxe) sont exécutés en premier. Ainsi, nous économisons des ressources de calcul et du temps d'exécution en rejetant immédiatement un code non conforme, avant d'engager les étapes plus lourdes (analyses de sécurité, estimation des coûts, plan d'exécution).

L'ordre séquentiel des étapes n'est pas arbitraire :
1. **Initialisation et Sécurisation** (Checkout, authentification AWS).
2. **Analyse Statique et Validation** (Formatage, initialisation, validation Terraform).
3. **Audits et Conformité** (Sécurité avec Checkov, FinOps avec Infracost).
4. **Tests de Configuration** (Linting Ansible).
5. **Projection** (Terraform Plan).

## 2. Justification Détaillée des Outils

### `actions/checkout@v4`
* **Rôle** : Récupérer le code source du dépôt dans l'environnement d'exécution (runner).
* **Justification** : C'est la base indispensable de toute CI/CD. La version `v4` a été choisie pour ses optimisations de performance de clone et son exécution sous Node 20.

### Authentification AWS (STS Assume Role CLI)
* **Rôle** : Générer des identifiants AWS temporaires via `aws sts assume-role` en s'appuyant sur les secrets GitHub.
* **Justification** : Le principe du moindre privilège. Plutôt que d'utiliser des credentials statiques de longue durée directement pour le déploiement, la pipeline assume un rôle spécifique (`role_etudiants`). Cela permet de limiter la portée temporelle des clés, réduisant considérablement la surface d'attaque en cas de fuite de la mémoire du runner.

### `hashicorp/setup-terraform@v3`
* **Rôle** : Installer une version précise du binaire Terraform (`1.8.0`).
* **Justification** : Assure l'idempotence et la reproductibilité environnementale stricte. L'absence de cet outil mènerait à utiliser la version par défaut du runner, susceptible de changer, ce qui causerait des dérives de state (State Drift) ou des incompatibilités de syntaxe de manière aléatoire.

### Commandes Terraform natives (`fmt`, `init`, `validate`, `plan`)
* **`terraform fmt -check -recursive`** : Impose un standard stylistique (lisibilité, maintenabilité). C'est la première étape "métier", qui permet de rejeter une Pull Request mal formatée.
* **`terraform init`** : Prépare l'espace de travail en téléchargeant fournisseurs et modules. Indispensable pour la suite.
* **`terraform validate`** : Vérifie l'intégrité syntaxique et les références croisées. Résout le problème des erreurs de dépendances (ex: appeler un output inexistant) avant de dialoguer avec l'API AWS.
* **`terraform plan`** : Offre une projection de l'état futur de l'infrastructure. Permet au relecteur de la Pull Request de comprendre l'impact physique (Création/Modification/Destruction) du code proposé.

### Checkov
* **Rôle** : Analyse Statique de Sécurité (SAST) appliquée à l'IaC.
* **Justification** : Il s'agit d'intégrer le paradigme "Shift-Left Security". Checkov scanne les ressources Terraform pour vérifier si elles respectent les règles de durcissement (chiffrement S3, règles de pare-feu restrictives, etc.). L'exécuter à ce stade prévient la création de failles d'infrastructure en production. Le `soft_fail: true` est ici un compromis contextuel toléré pour ce lab, afin de ne pas bloquer un apprentissage, mais en conditions réelles, l'échec devrait stopper la CI.

### Infracost
* **Rôle** : Estimer l'impact financier de la Pull Request (FinOps).
* **Justification** : Les déploiements cloud engendrent une dette financière. Infracost résout le problème des "factures surprises" en fournissant un devis détaillé directement dans la Pull Request et les résumés du Job GitHub (`GITHUB_STEP_SUMMARY`). Le relecteur valide ainsi non seulement l'architecture, mais aussi le budget.

### Setup Python & Ansible-Lint
* **Rôle** : Provisionner l'environnement pour exécuter l'outil de validation Ansible.
* **Justification** : Pour la partie Configuration Management (mise à jour du code Lambda), `ansible-lint` valide la syntaxe YAML du playbook, vérifie l'idempotence et le respect des conventions Ansible. L'absence de cette étape risquerait de laisser passer des playbooks instables, lents ou dépréciés.

## 3. Stratégie de Tests et Assurance Qualité

Dans ce projet purement IaC, il n'y a pas de tests applicatifs classiques (Unitaires/E2E). La stratégie repose sur la **validation et la vérification statique** :
* **Tests de conformité syntaxique** (`terraform validate`, `ansible-lint`) : Agissent comme des tests unitaires de base pour s'assurer que les fichiers de configuration sont interprétables.
* **Tests de qualité (Linting)** (`terraform fmt`) : Garantissent la pérennité du code, peu importe le nombre de contributeurs.
* **Tests de sécurité (SAST)** (Checkov) : Valident l'architecture par rapport aux normes CIS et aux bonnes pratiques AWS.

Cette stratégie empêche formellement qu'une Pull Request contenant du code buggé (mauvaise indentation YAML, oubli de variable Terraform, bucket S3 non sécurisé par principe) ne soit fusionnée.

## 4. Sécurité

Les mécanismes de sécurité de la pipeline répondent aux plus hautes exigences :
1. **Gestion des Secrets** : Aucun jeton sensible n'est présent dans le dépôt. L'authentification passe exclusivement par les secrets de dépôt GitHub (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `INFRACOST_API_KEY`).
2. **Moindre Privilège du Workflow** : Le bloc `permissions:` limite les droits du token `GITHUB_TOKEN` :
   * `contents: read` : Lecture seule sur le dépôt (empêche la modification sauvage).
   * `pull-requests: write` : Uniquement pour publier le rapport Infracost en commentaire.
3. **Session Temporaire (STS)** : Bien que des secrets long-terme soient dans GitHub Secrets, le workflow les utilise pour générer des tokens éphémères (`AWS_SESSION_TOKEN`).

## 5. Optimisations

* **Système d'Exploitation Unique** : Tout le job tourne dans une VM `ubuntu-latest`, évitant de lancer de multiples conteneurs ou jobs séparés, ce qui optimise le temps total de CI (réduction des frais généraux d'initialisation de machines).
* **Parallélisation conceptuelle des rapports** : Infracost génère ses données (`/tmp/infracost.json`) et est configuré de façon conditionnelle pour éviter l'échec du run s'il est indisponible (`continue-on-error: true`), garantissant ainsi la résilience du workflow.

## 6. Conformité aux Bonnes Pratiques DevOps / SysOps

La pipeline honore de multiples piliers DevOps :
* **Shift-Left Security et FinOps** : La sécurité (Checkov) et les coûts (Infracost) sont traités dès le développement (Pull Request).
* **Automatisation et Traçabilité** : Chaque commit est validé avec les mêmes règles strictes. Les logs, commentaires PR et Step Summaries créent un historique inaltérable et lisible.
* **Reproductibilité** : Figeage des versions (Terraform 1.8.0, Python 3.11, Actions v3/v4).
* **Fail Fast** : Le workflow plante en quelques secondes si un `terraform fmt` ou `validate` est défaillant, épargnant l'infrastructure GitHub.

## 7. Analyse Critique et Pistes d'Amélioration

Bien que robuste, l'architecture actuelle offre des marges de progression pour atteindre le standard "State of the Art" :

1. **Authentification OIDC (OpenID Connect) vs IAM User** :
   * **Constat** : Le script utilise `aws sts assume-role`, nécessitant tout de même de stocker des clés statiques d'IAM User dans GitHub Secrets.
   * **Amélioration** : Remplacer ceci par l'action `aws-actions/configure-aws-credentials` en configurant OIDC (OpenID Connect) entre GitHub et AWS. Cela permettrait de supprimer totalement les secrets AWS de GitHub, la confiance se faisant de manière cryptographique entre les fournisseurs d'identité.

2. **Permissivité de l'Assurance Qualité (`continue-on-error: true`)** :
   * **Constat** : Les étapes d'audit comme Checkov (`soft_fail: true`), Ansible Lint et Infracost ont le droit d'échouer sans faire planter la pipeline globale.
   * **Amélioration** : Dans un cadre d'entreprise, les erreurs critiques de sécurité ou de linter doivent casser le build (Hard Fail). On pourrait retirer ces drapeaux ou configurer des niveaux de sévérité stricts pour empêcher un déploiement insécurisé.

3. **Gestion du Cache (Performance)** :
   * **Constat** : À chaque exécution, Terraform télécharge à nouveau les fournisseurs (providers) et pip télécharge `ansible-lint`.
   * **Amélioration** : Implémenter `actions/cache` pour le dossier `.terraform/providers` et pour le cache `pip`. Cela réduirait drastiquement le temps de CI, en plus de limiter les requêtes sur des dépôts distants en cas de panne réseau externe.
