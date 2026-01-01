#!/bin/bash

# 1. Vérification de l'argument (Code langue)
if [ $# -ne 1 ]; then
    echo "Erreur : Ce programme demande exactement un argument (ex: fr, nrvg)."
    exit 1
fi

LANGUE=$1
compteur=1

# 2. Définition des chemins (Respect de l'arborescence)
FICHIER_URLS="../URLs/${LANGUE}_url.txt"
DOSSIER_IDOINE="../idoine/${LANGUE}"
FICHIER_HTML="../tableaux/${LANGUE}_site.html"

# Création des dossiers nécessaires s'ils n'existent pas
mkdir -p "../tableaux"
mkdir -p "$DOSSIER_IDOINE"

# Vérification que le fichier d'URLs existe
if [ ! -f "$FICHIER_URLS" ]; then
    echo "Erreur : Le fichier $FICHIER_URLS est introuvable."
    exit 1
fi

# 3. Écriture de l'en-tête HTML (Style Bleu Marine)
echo "Création de l'en-tête HTML..."
cat <<EOF > "$FICHIER_HTML"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <title>Tableau URLS - $LANGUE</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@1.0.4/css/bulma.min.css" />
    <style>
        body { font-family: 'Segoe UI', Roboto, Arial, sans-serif; background-color: #ffffff; color: #000; }
        .title { color: #1e3a8a !important; }
        /* Style du tableau épuré */
        .table-epure { width: 100%; border-collapse: collapse; background-color: #fff; }
        .table-epure th, .table-epure td { border: 2px solid #1e3a8a; padding: 12px 15px; color: #000; }
        .table-epure th { background-color: #f8f9fa; font-weight: bold; border-bottom: 3px solid #1e3a8a; text-align: center; }
        .table-epure tr:hover { background-color: #eef2ff; }
    </style>
</head>
<body>
<section class="section">
    <div class="container">
        <article class="message is-info" style="background-color: #1e3a8a; border: none;">
            <div class="message-body" style="color: white; border: none;">
                Tableaux des URLS ($LANGUE)
            </div>
        </article>
        <h2 class="title is-2 has-text-centered">Tableau d'analyse des URLs</h2><br>
        
        <table class="table-epure">
            <thead>
                <tr>
                    <th>Ligne</th>
                    <th>Code HTTP</th>
                    <th>Encodage</th>
                    <th>Mots</th>
                    <th>URL</th>
                </tr>
            </thead>
            <tbody>
EOF

# 4. Boucle de traitement ligne par ligne
echo "Traitement des URLs en cours..."

while read -r line; do
    # -- A. Récupération --
    # On télécharge la page dans un fichier temporaire pour ne faire qu'une requête
    code_http=$(curl -s -L -o "page_temp.html" -w "%{http_code}" "$line")

    # -- B. Encodage --
    # Utilisation de 'file' (plus robuste) ou fallback
    encodage=$(file -b --mime-encoding "page_temp.html" 2>/dev/null)
    if [ -z "$encodage" ]; then
        encodage="inconnu"
    fi

    # -- C. Comptage --
    # On enlève les balises HTML (<...>) pour compter les vrais mots
    nb_mots=$(sed 's/<[^>]*>/ /g' "page_temp.html" | wc -w)

    # -- D. Sauvegarde --
    # On déplace le fichier temporaire vers le dossier idoine
    mv "page_temp.html" "${DOSSIER_IDOINE}/${LANGUE}-${compteur}.txt"

    # -- E. Nettoyage (CRITIQUE) --
    # On supprime les retours à la ligne qui cassent le tableau HTML
    code_http=$(echo "$code_http" | tr -d '\n\r')
    encodage=$(echo "$encodage" | tr -d '\n\r')
    nb_mots=$(echo "$nb_mots" | tr -d '\n\r')

    # -- F. Écriture HTML --
    echo "                <tr>" >> "$FICHIER_HTML"
    echo "                    <td>$compteur</td>" >> "$FICHIER_HTML"
    echo "                    <td>$code_http</td>" >> "$FICHIER_HTML"
    echo "                    <td>$encodage</td>" >> "$FICHIER_HTML"
    echo "                    <td>$nb_mots</td>" >> "$FICHIER_HTML"
    echo "                    <td><a href=\"$line\" target=\"_blank\">$line</a></td>" >> "$FICHIER_HTML"
    echo "                </tr>" >> "$FICHIER_HTML"

    echo "Url $compteur traitée : $line"
    compteur=$((compteur + 1))

done < "$FICHIER_URLS"

# 5. Fermeture du fichier HTML
echo "            </tbody>" >> "$FICHIER_HTML"
echo "        </table>" >> "$FICHIER_HTML"
echo "    </div>" >> "$FICHIER_HTML"
echo "</section>" >> "$FICHIER_HTML"
echo "</body></html>" >> "$FICHIER_HTML"

echo "Terminé ! Fichier généré : $FICHIER_HTML"