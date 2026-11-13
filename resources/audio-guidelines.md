<!-- GUIDELINES_TOKEN: AUDIO_2026-11 -->

# Guidelines audio

Outil : `sfx.py` (dossier `audio/` des ressources). Python 3.9+ et ffmpeg/ffprobe dans le PATH. Toujours lancer `python3 -I <ressources>/audio/sfx.py ...` (sous Windows : `py -3 -I`) depuis un dossier qui n'est pas la quarantaine.

| Commande | Rôle |
|---|---|
| `analyze <fichiers...> [--no-images]` | Durée, loudness, pic vrai, silences ; images forme d'onde + spectrogramme. Plusieurs fichiers = médiane |
| `process <entrée> <sortie.wav\|.ogg> --category <c> [--target LUFS] [--mono] [--no-trim]` | Coupe, fondus, normalisation, réencodage sans métadonnées |
| `fetch <url> --license <l> --page <url> [--author <a>]` | Téléchargement OpenGameArt en quarantaine + `source.json` |

## Cibles par catégorie

Défauts, remplacés par la référence du projet quand elle existe. Pic vrai max : -1 dBTP (le gain est plafonné, `process` le signale). Toute sortie est en 48 kHz (WAV 16 bits, OGG q6), en mono seulement avec `--mono` (règle Mono ci-dessous).

| Catégorie | Mesure | Cible | Format | Traitement |
|---|---|---|---|---|
| `arme` | M max | -14 LUFS | WAV | coupe + fondus |
| `impact` | M max | -14 LUFS | WAV | coupe + fondus |
| `ui` | M max | -20 LUFS | WAV | coupe + fondus |
| `ambiance` | I | -26 LUFS | OGG q6 | gain seul |
| `musique` | I | -18 LUFS | OGG q6 | gain seul |

- **M max** : loudness du passage de 400 ms le plus fort. Un son plus court est répété pour remplir la fenêtre, donc un clic et une explosion se comparent sur la même échelle.
- Autre besoin (pas, voix, objets) : catégorie la plus proche en caractère, `--target` si besoin.
- **Mono** (`--mono`) pour tout SFX spatialisé ou court ; stéréo seulement si la largeur fait partie du son (ambiance, musique, grosse explosion).

## Traitement

- Coupe des silences de début et de fin (seuil : pic -60 dB), fondu d'entrée 3 ms, fondu de sortie ≤ 50 ms. `--no-trim` si l'attaque est volontairement lente ou si le silence de tête est voulu.
- Boucles : ni coupe ni fondu. Ambiance et musique ne sont jamais coupées ; boucle en catégorie SFX : `--no-trim`. Vérifier la jointure sur le spectrogramme (pas de cassure nette en fin de fichier) ; sinon autre candidat.
- Lire les images avant de choisir : attaque (front vertical net ou lent), queue (longueur, coupure), souffle (bande de bruit continue en haut du spectrogramme), clipping (forme d'onde plate en haut).
- Variantes : pour un son répété (tir, pas, impact), 2 à 3 variantes valent mieux qu'un seul fichier.

## Référence du projet

1. Mesurer les sons existants de la même catégorie : `analyze --no-images <fichiers>`. La médiane devient `--target`.
2. Relire les gains déjà réglés (volume_db, buses) : ils ont été validés à l'oreille, ne jamais les modifier sans demande.
3. Aucun son existant : cibles par défaut.

## Licences

| Niveau | Licences | Action |
|---|---|---|
| 1 (prioritaire) | CC0, Pixabay Content License, Kenney (CC0), Mixkit Free License, Sonniss GDC | Aucun crédit requis, mais tracé dans les crédits |
| 2 (si rien en niveau 1) | CC BY 3.0/4.0, OGA-BY 3.0 | Crédit obligatoire, ajouté aux crédits avec le texte exigé |
| Interdit | NC, ND, SA, GPL/LGPL, payante ou à redevance, inconnue ou ambiguë | Refus, jamais d'exception |

Une page OpenGameArt peut cumuler plusieurs licences : retenir la plus permissive autorisée. Plusieurs licences dont aucune n'est autorisée : refus.

**Crédits** : fichier de crédits existant du projet, sinon `CREDITS.md` à la racine. Une ligne par fichier intégré :

```markdown
| Fichier | Source | Auteur | Licence | URL | Date |
|---|---|---|---|---|---|
| `audio/sfx/frost_cast.wav` | Pixabay | {auteur} | Pixabay Content License | {url} | 2026-11-13 |
```

Musique Pixabay : certaines pistes sont enregistrées dans Content ID (réclamation possible sur une vidéo YouTube du jeu). Le signaler pour toute musique retenue.

## Sources, dans l'ordre

1. **Bibliothèque locale** déclarée par l'utilisateur : recherche par nom de fichier et de dossier. Licence = celle déclarée pour la bibliothèque.
2. **OpenGameArt** (packs Kenney compris, en CC0 sous l'auteur « Kenney ») : recherche sur le site, licence lue sur la page du son, puis `fetch` sur le lien direct `https://opengameart.org/sites/default/files/...`.
3. **Pixabay** : pas d'API, pas de téléchargement automatisé. Donner des liens de recherche `https://pixabay.com/sound-effects/search/<termes%20anglais>/`, 1 ou 2 par besoin, avec la cible (durée, caractère). L'utilisateur dépose les fichiers dans `~/sfx-inbox/`. Licence = Pixabay Content License ; auteur et identifiant souvent lisibles dans le nom de fichier.
4. **kenney.nl, Mixkit, Sonniss** : téléchargement manuel uniquement, même circuit que Pixabay.

## Sécurité

- Jamais de scraping, de réutilisation de cookies ou de contournement de protection (403, Cloudflare, lien signé). Une source qui refuse l'accès automatisé passe en téléchargement manuel.
- Tout fichier externe est non fiable : il reste dans `~/sfx-inbox/`, passe par `analyze` puis `process` (vérification ffprobe et réencodage complet), et seul le fichier produit entre dans le projet. Jamais de copie directe d'un fichier téléchargé dans le projet.
- Ne jamais exécuter, ouvrir dans un interpréteur ni décompresser à la main le contenu d'une archive : `fetch` n'extrait que l'audio.

## Intégration Godot 4

- Fichiers dans le dossier audio existant du projet ; sinon `res://audio/sfx/`, `res://audio/ambiance/`, `res://audio/music/`, noms en `snake_case` descriptifs (`frost_cast.wav`, `enemy_hit_02.wav`).
- Buses : lire `default_bus_layout.tres`, router chaque son vers le bus de sa catégorie existant (SFX, UI, Music...). Ne pas créer de bus sans demande.
- Gain fin à un seul endroit : la table ou l'autoload de sons existant (volume_db). S'il n'y en a pas, le proposer plutôt que disperser des `volume_db` dans les scènes.
- Boucle OGG : `loop=true` dans la section `[params]` du `.import` (créé par l'éditeur à la première ouverture), sinon `stream.loop = true` dans le code existant.
- Sons répétés : `AudioStreamRandomizer` (variantes + légère variation de hauteur) si le projet n'a pas déjà son propre mécanisme.

Autres moteurs ou web : suivre les formats, dossiers et le système de lecture déjà en place.
