# Vario VL — vario barométrique pour iPhone (version 0.1)

Application iPhone de Laurent (compte GitHub **Noyau007**, dépôt prévu : **vario-vl**).

## Ce qu'elle fait
- **Vario** à partir du baromètre de l'iPhone (filtre de Kalman), en grand, vert en montée, rouge en forte descente.
- **Son** : bips de plus en plus aigus et rapides en montée, son grave continu en forte descente (seuils réglables).
- **Altitude barométrique**, calée automatiquement sur le GPS au démarrage, ou à la main (bouton « Caler sur le GPS »
  ou altitude connue, par ex. celle du déco).
- **Moyenne sur 20 s**, vitesse sol, cap, altitude GPS et sa précision, pression, nombre de mesures par seconde.
- **Écran toujours allumé** ; le **son et le GPS continuent écran verrouillé** (point à vérifier sur l'iPhone).
- Aide au vol seulement : ne remplace pas un instrument certifié.

## Fabriquer l'application (sans Mac, gratuit)
1. Créer sur GitHub un dépôt **vario-vl** (public : compilation gratuite sans limite ; privé : environ 200 minutes
   de compilation Mac par mois, largement assez).
2. Y mettre tout le contenu de ce dossier, **y compris le dossier caché `.github`** (soit avec git, soit sur
   github.com : *Add file → Upload files*, en glissant les dossiers).
3. Onglet **Actions** du dépôt : la compilation « Compiler Vario VL » se lance à chaque envoi (environ 5 minutes).
   Elle vérifie d'abord les calculs, puis compile. En cas d'échec, copier le message d'erreur à Claude.
4. Quand elle est verte : ouvrir la compilation, télécharger l'artefact **VarioVL-ipa** (un .zip qui contient
   `VarioVL.ipa`).

## Installer sur l'iPhone (PC Windows, gratuit)
1. Installer **iTunes depuis le site d'Apple** (pas la version du Microsoft Store), puis **Sideloadly** (sideloadly.io).
2. Brancher l'iPhone en USB, le déverrouiller, accepter « Faire confiance à cet ordinateur ».
3. Dans Sideloadly : choisir l'iPhone, saisir son identifiant Apple, glisser `VarioVL.ipa`, cliquer sur **Start**.
4. Sur l'iPhone :
   - **Réglages → Confidentialité et sécurité → Mode développeur** : activer, redémarrer, confirmer.
   - **Réglages → Général → VPN et gestion de l'appareil** : faire confiance au développeur (ton identifiant Apple).
5. Ouvrir Vario VL, accepter le baromètre (« Mouvements et forme ») et la localisation.

Avec un identifiant Apple gratuit, l'application **expire au bout de 7 jours** : refaire l'étape 3 chaque semaine
(sans supprimer l'application, les réglages sont gardés). Avec un compte développeur Apple (99 $/an), elle tient un an.

## Premiers essais à faire (et à rapporter)
- Le nombre de **mesures par seconde** affiché en bas (il décide de la réactivité du vario).
- Le vario à l'arrêt sur une table (doit rester proche de 0), puis en montant un escalier (environ +0,3 à +0,5 m/s).
- Le **son écran verrouillé**.
- Le calage automatique sur le GPS (altitude affichée par rapport à l'altitude connue du lieu).

## Fichiers
- `VarioVL/Calculs.swift` : altitude, filtre du vario, moyenne, son (sans dépendance à iOS).
- `VarioVL/Modele.swift` : baromètre (CMAltimeter), GPS, réglages mémorisés.
- `VarioVL/Son.swift` : générateur de son. `VarioVL/Ecran.swift` : écrans. `VarioVL/App.swift` : démarrage.
- `Verification/main.swift` : tests des calculs, lancés avant chaque compilation.
- `project.yml` : description du projet Xcode (XcodeGen). `.github/workflows/compiler.yml` : compilation automatique.

Suite prévue : enregistrement de la trace (IGC), espaces aériens et cône ou triangle du jour repris de Planif vol,
alertes d'espaces aériens en hauteur grâce au baromètre.
