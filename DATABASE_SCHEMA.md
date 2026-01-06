# Architecture API & Base de Données - Constellation

## 📋 Vue d'ensemble

L'application Constellation suit une architecture **hybride** combinant :
- **API RNA** (OpenData) : Données publiques des associations françaises
- **Backend Constellation** : Données enrichies par la communauté

## 🗄️ Schéma de Base de Données (Backend)

### Table: `users`
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    nom VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    ville VARCHAR(100),
    biographie TEXT,
    date_inscription TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    est_president BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
```

### Table: `associations_enriched`
```sql
CREATE TABLE associations_enriched (
    id VARCHAR(20) PRIMARY KEY, -- ID RNA
    description TEXT,
    site_web VARCHAR(255),
    email VARCHAR(255),
    telephone VARCHAR(20),
    logo_url TEXT,
    photos TEXT[], -- Array de URLs
    categorie VARCHAR(50),
    est_revendiquee BOOLEAN DEFAULT FALSE,
    president_id UUID REFERENCES users(id),
    date_revendication TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_associations_categorie ON associations_enriched(categorie);
CREATE INDEX idx_associations_president ON associations_enriched(president_id);
```

### Table: `comments`
```sql
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    association_id VARCHAR(20) NOT NULL, -- Référence à RNA
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contenu TEXT NOT NULL,
    note INTEGER CHECK (note >= 1 AND note <= 5),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_comments_association ON comments(association_id);
CREATE INDEX idx_comments_user ON comments(user_id);
CREATE INDEX idx_comments_date ON comments(date_creation DESC);
```

### Table: `ratings`
```sql
CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    association_id VARCHAR(20) NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    note INTEGER NOT NULL CHECK (note >= 1 AND note <= 5),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(association_id, user_id) -- Un utilisateur = une note par association
);

CREATE INDEX idx_ratings_association ON ratings(association_id);
CREATE INDEX idx_ratings_user ON ratings(user_id);
```

### Table: `claims` (Revendications)
```sql
CREATE TABLE claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    association_id VARCHAR(20) NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    justification TEXT,
    statut VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    date_demande TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_traitement TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_claims_association ON claims(association_id);
CREATE INDEX idx_claims_user ON claims(user_id);
CREATE INDEX idx_claims_statut ON claims(statut);
```

### Vue: `associations_stats` (Matérialisée)
```sql
CREATE MATERIALIZED VIEW associations_stats AS
SELECT 
    r.association_id,
    AVG(r.note) as note_moyenne,
    COUNT(r.id) as nombre_notes,
    COUNT(DISTINCT c.id) as nombre_commentaires,
    jsonb_build_object(
        '1', COUNT(CASE WHEN r.note = 1 THEN 1 END),
        '2', COUNT(CASE WHEN r.note = 2 THEN 1 END),
        '3', COUNT(CASE WHEN r.note = 3 THEN 1 END),
        '4', COUNT(CASE WHEN r.note = 4 THEN 1 END),
        '5', COUNT(CASE WHEN r.note = 5 THEN 1 END)
    ) as repartition_notes
FROM ratings r
LEFT JOIN comments c ON c.association_id = r.association_id
GROUP BY r.association_id;

CREATE UNIQUE INDEX idx_associations_stats_id ON associations_stats(association_id);

-- Rafraîchissement automatique (optionnel, selon la charge)
-- CREATE OR REPLACE FUNCTION refresh_associations_stats()
-- RETURNS trigger AS $$
-- BEGIN
--     REFRESH MATERIALIZED VIEW CONCURRENTLY associations_stats;
--     RETURN NULL;
-- END;
-- $$ LANGUAGE plpgsql;
```

## 🔌 API Endpoints

### Authentification
```
POST   /api/auth/register      - Inscription
POST   /api/auth/login         - Connexion
POST   /api/auth/logout        - Déconnexion
GET    /api/auth/me            - Profil utilisateur
```

### Associations
```
GET    /api/associations/:id              - Données enrichies
PUT    /api/associations/:id              - Mise à jour (président)
GET    /api/associations/:id/stats        - Statistiques
```

### Commentaires
```
GET    /api/comments?association_id=:id   - Liste des commentaires
POST   /api/comments                      - Ajouter un commentaire
PUT    /api/comments/:id                  - Modifier (auteur)
DELETE /api/comments/:id                  - Supprimer (auteur/admin)
```

### Notes
```
GET    /api/ratings/stats/:association_id - Statistiques de notation
POST   /api/ratings                       - Noter/Modifier sa note
GET    /api/ratings/user/:user_id         - Notes d'un utilisateur
```

### Revendications
```
POST   /api/claims                        - Revendiquer une association
GET    /api/claims/user                   - Mes revendications
PUT    /api/claims/:id                    - Traiter (admin)
```

## 🔐 Sécurité

### Authentification JWT
```javascript
// Token structure
{
  "user_id": "uuid",
  "email": "user@example.com",
  "est_president": false,
  "iat": 1234567890,
  "exp": 1234567890
}
```

### Règles de sécurité
1. **Commentaires** : Seul l'auteur peut modifier/supprimer
2. **Notes** : Un utilisateur = une note par association
3. **Associations** : Seul le président peut modifier
4. **Revendications** : Traitement par admin uniquement
5. **Mots de passe** : bcrypt avec salt rounds = 10

### Variables d'environnement (.env)
```bash
# Base de données
DATABASE_URL=postgresql://user:password@localhost:5432/constellation

# JWT
JWT_SECRET=votre_secret_securise_aleatoire
JWT_EXPIRATION=7d

# API RNA
RNA_API_URL=https://entreprise.data.gouv.fr/api/rna/v1

# Port
PORT=3000
NODE_ENV=development
```

## 📊 Flux de Données

```
┌─────────────┐
│   Flutter   │
│     App     │
└──────┬──────┘
       │
       ├─────────────────┐
       │                 │
       ▼                 ▼
┌─────────────┐   ┌──────────────┐
│  API RNA    │   │   Backend    │
│  (OpenData) │   │ Constellation│
└─────────────┘   └──────┬───────┘
                         │
                         ▼
                  ┌──────────────┐
                  │  PostgreSQL  │
                  │   Database   │
                  └──────────────┘
```

### Processus de récupération d'une association
1. App demande l'association X
2. Repository appelle RNA API → Données publiques
3. Repository appelle Backend → Données enrichies
4. Fusion des données côté client
5. Affichage dans l'interface

## 🚀 Mise en place

### Prérequis Backend
```bash
# Node.js backend (exemple)
npm install express pg jsonwebtoken bcrypt cors dotenv

# Base de données
psql -U postgres -c "CREATE DATABASE constellation;"
psql -U postgres -d constellation -f schema.sql
```

### Configuration Flutter
Modifier `lib/config/api_config.dart` :
```dart
static const String backendBaseUrl = 'http://votre-serveur:3000/api';
```

### Pour développement local
- Android émulateur : `http://10.0.2.2:3000/api`
- iOS simulateur : `http://localhost:3000/api`
- Device physique : `http://192.168.x.x:3000/api`

## 📝 Notes Importantes

1. **API RNA** : Pas d'authentification requise, données publiques
2. **Backend** : JWT Bearer token pour routes protégées
3. **Cache** : Implémenter un cache local pour les données RNA
4. **Offline** : Utiliser `sqflite` pour le mode hors ligne
5. **Pagination** : Limiter les résultats (20 par page recommandé)

## 🔄 Synchronisation

Les données RNA sont **en lecture seule**. Les enrichissements sont stockés localement dans le backend et synchronisés avec l'app.

Pour garantir la cohérence :
- Rafraîchir les stats toutes les 5 minutes
- Invalider le cache après une action utilisateur
- Gérer les conflits avec timestamps

---

**Note** : Ce document décrit l'architecture complète. Le backend doit être implémenté séparément (Node.js/Express, Python/Django, etc.)
