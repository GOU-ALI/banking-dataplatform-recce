# Plateforme de Données Bancaires - POC dbt + Recce

![dbt version](https://img.shields.io/badge/dbt-1.10.6-orange)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13+-blue)
![Recce](https://img.shields.io/badge/Recce-1.13.0-green)
![License](https://img.shields.io/badge/license-MIT-blue)
# Plateforme de Données Bancaires - POC dbt + Recce

Une preuve de concept simple démontrant comment Recce aide à détecter les changements de données dans un pipeline de données bancaires construit avec dbt.

## 🎯 Objectif

Ce projet démontre comment utiliser **Recce** pour valider les transformations de données à travers les couches Bronze → Silver → Gold dans un contexte bancaire, en détectant les erreurs de calcul avant qu'elles n'atteignent la production.

## 🏗️ Architecture

```
Couche Bronze (Brut) → Couche Silver (Nettoyé) → Couche Gold (Analytique)
        ↓                      ↓                        ↓
  Vue: Données brutes    Table: Conversion MAD    Table: Résumés quotidiens
                               ↓
                    Recce valide les changements entre Dev et Prod
```

## 📁 Structure du Projet

```
banking_dataplatform/
├── models/
│   ├── bronze/
│   │   └── brz_transactions.sql      # Données de transactions brutes
│   ├── silver/
│   │   └── slv_transactions.sql      # Nettoyé avec conversion en MAD
│   └── gold/
│       └── gld_daily_summary.sql     # Agrégations quotidiennes
├── dbt_project.yml                   # Configuration dbt
├── profiles.yml                      # Connexions base de données
├── recce.yml                         # Vérifications de validation Recce
└── README.md                         # Ce fichier
```

## 🚀 Démarrage Rapide

### Prérequis

- PostgreSQL en cours d'exécution sur localhost:5432
- Python 3.8+ avec environnement virtuel
- dbt-postgres installé
- Recce installé

### Installation

```bash
# Cloner ou créer le projet
cd ~/Documents/dbt-poc/banking_dataplatform

# Installer les dépendances
pip install dbt-postgres recce

# Vérifier la connexion PostgreSQL
dbt debug
```

### Configuration de la Base de Données

```sql
-- Créer la base de données si elle n'existe pas
CREATE DATABASE dbt_test_recce;

-- Les schémas seront créés automatiquement :
-- banking_dev (environnement de développement)
-- banking_prod (environnement de production)
```

## 🔄 Exécution du Pipeline de Données

### 1. Créer la Base de Production

```bash
# Construire l'environnement de production (référence)
dbt run --target prod --target-path target-base
dbt docs generate --target prod --target-path target-base
```

### 2. Construire l'Environnement de Développement

```bash
# Construire l'environnement de développement (avec vos changements)
dbt run --target dev
dbt docs generate --target dev
```

### 3. Exécuter la Validation Recce

```bash
# Vérifier la configuration Recce
recce debug

# Exécuter les vérifications de validation
recce run

# Lancer l'interface interactive
recce server
# S'ouvre à http://localhost:8000
```

## 📊 Exemple de Cas d'Usage : Changement de Taux de Conversion de Devises

### Scénario
Nous devons mettre à jour le taux de change EUR vers MAD de 10.8 à 11.2 dans notre couche silver.

### Étape 1 : Effectuer le Changement

Modifier `models/silver/slv_transactions.sql` :

```sql
-- Changer cette ligne :
WHEN currency = 'EUR' THEN amount * 10.8  -- ANCIEN taux

-- Par celle-ci :
WHEN currency = 'EUR' THEN amount * 11.2  -- NOUVEAU taux
```

### Étape 2 : Reconstruire le Développement

```bash
dbt run --target dev
dbt docs generate --target dev
```

### Étape 3 : Valider avec Recce

```bash
recce server
```

### Ce que Recce Montre

Dans l'interface à http://localhost:8000 :

1. **Vue Lineage** : 
   - `slv_transactions` surligné comme "modifié"
   - `gld_daily_summary` marqué comme "impact en aval"

2. **Vérification du Nombre de Lignes** : ✅ Aucun changement (même 100 transactions)

3. **Différences de Valeurs** :
   ```
   Comparaison du Volume Quotidien :
   Date         | Production    | Développement | Changement
   2025-01-15   | 52,345.50 MAD | 54,123.00 MAD | +3.4%
   2025-01-14   | 41,232.00 MAD | 42,655.20 MAD | +3.5%
   ```

4. **Analyse d'Impact** : 
   - Impact total sur les revenus : +22,730 MAD
   - Affecte toutes les transactions EUR (~30% du volume)
   - Risque : Pourrait impacter les rapports financiers

## 🧪 Vue d'Ensemble des Modèles

### Couche Bronze : `brz_transactions`
- **Objectif** : Données de transactions brutes
- **Type** : Vue
- **Colonnes** : transaction_id, montant, devise, date

### Couche Silver : `slv_transactions`
- **Objectif** : Données nettoyées avec conversion en MAD
- **Type** : Table
- **Transformations** :
  - Conversion de devises (EUR→MAD, USD→MAD)
  - Filtrage des transactions invalides (montant > 0)

### Couche Gold : `gld_daily_summary`
- **Objectif** : Métriques commerciales quotidiennes
- **Type** : Table
- **Métriques** :
  - Total des transactions par jour
  - Volume total en MAD
  - Taille moyenne des transactions

## 📋 Configuration des Vérifications Recce

```yaml
# recce.yml
checks:
  - Vérification du Nombre de Lignes  # Détecte les données manquantes/dupliquées
  - Vérification du Schéma            # Détecte les changements de colonnes
```

## 🎯 Principaux Avantages Démontrés

1. **Détecter les Erreurs de Calcul** : Changement de taux EUR détecté immédiatement
2. **Quantifier l'Impact** : Montre la différence exacte en MAD dans les rapports
3. **Prévenir les Problèmes en Production** : Tester les changements en toute sécurité en dev
4. **Piste d'Audit** : Suivre tous les changements du pipeline de données

## 🔍 Utilisation de l'Interface Recce

1. **Onglet Lineage** : DAG visuel de votre flux de données
2. **Onglet Query** : Exécuter des comparaisons SQL personnalisées
3. **Onglet Checklist** : Voir les résultats des vérifications automatisées

### Requêtes Rapides à Essayer

Dans l'onglet Query, sélectionnez un modèle et exécutez :

```sql
-- Comparer les totaux
SELECT COUNT(*) as lignes, SUM(total_volume_mad) as total
FROM {{ model }}

-- Vérifier les tendances quotidiennes
SELECT transaction_date, total_volume_mad
FROM {{ model }}
ORDER BY transaction_date DESC
LIMIT 5
```

## 📝 Commandes Courantes

```bash
# Tout nettoyer
dbt clean

# Exécuter des modèles spécifiques
dbt run --select slv_transactions+  # Exécuter le modèle et l'aval
dbt run --select +gld_daily_summary  # Exécuter le modèle et l'amont

# Tester la qualité des données
dbt test

# Voir le lineage
dbt docs generate
dbt docs serve
```

## ⚠️ Dépannage

### Problème : "la relation n'existe pas"
**Solution** : Les tables sont préfixées avec les noms de schéma. Utilisez les sélecteurs de modèles dans l'interface Recce au lieu de taper les noms de tables.

### Problème : Aucune différence affichée
**Solution** : Assurez-vous d'avoir exécuté les deux cibles :
```bash
dbt run --target prod --target-path target-base
dbt run --target dev
```

### Problème : Connexion refusée
**Solution** : Vérifier que PostgreSQL fonctionne :
```bash
psql -U postgres -d dbt_test_recce -c "SELECT 1"
```

## 📚 En Savoir Plus

- [Documentation dbt](https://docs.getdbt.com/)
- [Documentation Recce](https://docs.datarecce.io/)
- [Meilleures Pratiques dbt](https://docs.getdbt.com/best-practices)

## 👤 Auteur

Créé comme POC pour comprendre les capacités de validation des données de Recce dans les pipelines de données bancaires.

---

**Note** : Ceci est un exemple simplifié utilisant des données générées. En production, vous auriez :
- Des sources de données de transactions réelles
- Des règles métier complexes
- Plusieurs devises et réglementations (y compris les normes Bank Al-Maghrib)
- Des tests de qualité des données
- Une intégration CI/CD avec les vérifications Recce
- Conformité avec les réglementations bancaires marocaines