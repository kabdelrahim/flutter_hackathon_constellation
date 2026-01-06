# Déclaration d’utilisation d’un agent conversationnel (IA)

## Contexte du projet

Le projet **Constellation – Annuaire des associations** vise à répondre à une problématique
nationale : bien que la France compte plus de 1,5 million d’associations, les informations les
concernant sont souvent dispersées, peu accessibles et difficilement exploitables à l’échelle
locale.

L’objectif de Constellation est de proposer une plateforme hybride, à la fois **annuaire** et
**réseau social**, permettant à tout citoyen, où qu’il se trouve en France, de découvrir les
associations autour de lui.  
Les utilisateurs doivent pouvoir :
- rechercher des associations selon différents critères (nom, catégorie, adresse, mots-clés),
- consulter des informations détaillées,
- partager leur expérience via des commentaires et des notes,
- interagir avec les associations (demande d’adhésion).

Les présidents d’associations doivent quant à eux pouvoir **revendiquer leur page** afin de
l’animer (informations, actualités, photos, recrutement), favorisant une dimension sociale
collaborative.

---

## Données et principes techniques

Le projet repose sur deux piliers principaux :

1. **L’OpenData**  
   Les données initiales proviennent du Répertoire National des Associations (RNA), exploité via
   une API publique. Ces données constituent la base statique de l’annuaire.

2. **L’enrichissement par base de données**  
   Les données OpenData sont enrichies par des fonctionnalités dynamiques telles que :
   - comptes utilisateurs,
   - commentaires,
   - notes,
   - modifications et ajouts communautaires.

La plateforme intègre également une **cartographie** (type OpenStreetMap ou Google Maps) afin
d’afficher les associations de manière géographique.

---

## Sécurité et livrables

Une attention particulière est portée à la sécurité de la plateforme, notamment concernant :
- la gestion des accès,
- la protection des données personnelles,
- la fiabilité des interactions utilisateurs.

Les livrables attendus incluent :
- un dépôt Git documenté,
- un code commenté justifiant les choix techniques,
- une charte d’utilisation des outils d’aide (dont les agents conversationnels),
- une vidéo de présentation des fonctionnalités et choix techniques.

---

## Instructions données à l’agent conversationnel

Dans le cadre de l’assistance apportée par un agent conversationnel (IA), les instructions
suivantes ont été définies :

- respecter strictement le **contexte fonctionnel du projet Constellation** tel que décrit
  ci-dessus ;
- proposer des solutions et du code en adéquation avec les objectifs de la plateforme
  (annuaire enrichi à dimension sociale) ;
- respecter le **découpage architectural imposé du projet**, notamment l’architecture
  **MVC en Flutter/Dart**, incluant une séparation claire entre :
  - modèles de données,
  - vues (interfaces utilisateur),
  - contrôleurs (logique applicative) ;
- ne pas proposer de fonctionnalités ou de structures incompatibles avec les contraintes
  pédagogiques et techniques du projet.

L’agent est utilisé comme un **outil d’assistance à la réflexion, à la structuration et à la
compréhension**, et non comme un générateur autonome du projet.
