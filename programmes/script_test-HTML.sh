#!/bin/bash

# 1. Vérification de l'argument
if [ $# -ne 1 ]; then
    echo "Ce programme demande un argument (fr, ang, nrvg)."
    exit 1
fi

LANGUE=$1
compteur=1

# 2. Définition du mot clé selon la langue
if [[ $LANGUE == "fr" ]]; then
    MOT="flotte"
elif [[ $LANGUE == "ang" ]]; then
    MOT="fleet"
elif [[ $LANGUE == "nrvg" ]]; then
    MOT="flåte"
else
    MOT=""
    echo "Attention : Langue non reconnue."
fi

# 3. Création de TOUS les dossiers nécessaires
mkdir -p "../URLs"
mkdir -p "../tableaux"
mkdir -p "../idoine/${LANGUE}"
mkdir -p "../dumps-text/${LANGUE}"
mkdir -p "../contextes/${LANGUE}"

FICHIER_URLS="../URLs/${LANGUE}_url.txt"
FICHIER_HTML="../tableaux/${LANGUE}_site.html"

# Vérification fichier URL
if [ ! -f "$FICHIER_URLS" ]; then
    echo "Erreur : Le fichier $FICHIER_URLS est introuvable."
    exit 1
fi

# 4. Écriture de l'en-tête HTML
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
        .table-epure { width: 100%; border-collapse: collapse; background-color: #fff; table-layout: auto; }
        .table-epure th, .table-epure td { border: 2px solid #1e3a8a; padding: 12px 15px; color: #000; vertical-align: middle; }
        .table-epure th { background-color: #f8f9fa; font-weight: bold; border-bottom: 3px solid #1e3a8a; text-align: center; white-space: nowrap; }
        .table-epure tr:hover { background-color: #eef2ff; }
        /* Colonne URL large, les autres ajustées */
        .table-epure td:nth-child(5) { word-break: break-all; min-width: 200px; }
        .button.is-small { font-size: 0.8rem; }
    </style>
</head>
<body>
<section class="section">
    <div class="container">
        <h2 class="title is-2 has-text-centered">Tableau d'analyse des URLs ($LANGUE)</h2><br>
        <table class="table-epure">
            <thead>
                <tr>
                    <th>Ligne</th>
                    <th>Code</th>
                    <th>Encodage</th>
                    <th>Mots</th>
                    <th>URL</th>
                    <th>Aspiré</th>
                    <th>Dump</th>
                    <th>Contexte</th>
                </tr>
            </thead>
            <tbody>
EOF

# 5. Boucle de traitement
echo "Traitement des URLs pour : $MOT"

while read -r line; do
    # -- A. Téléchargement unique --
    code_http=$(curl -s -L -o "page_temp.html" -w "%{http_code}" "$line")

    if [ ! -s "page_temp.html" ]; then
        echo "Erreur téléchargement pour $line"
        code_http="ERR"
        encodage="inconnu"
        nb_mots="0"
    else
        # -- B. Encodage --
        encodage=$(file -b --mime-encoding "page_temp.html")

        # Conversion si nécessaire
        if [[ "$encodage" != "utf-8" && "$encodage" != "us-ascii" ]]; then
            iconv -f "$encodage" -t utf-8 "page_temp.html" > "page_temp_utf8.html" 2>/dev/null
            if [ $? -eq 0 ]; then
                mv "page_temp_utf8.html" "page_temp.html"
                encodage="$encodage (conv)"
            fi
        fi

        # -- C. Sauvegardes --
        # 1. Page Aspirée (HTML)
        cp "page_temp.html" "../idoine/${LANGUE}/${LANGUE}-${compteur}.html"

        # 2. Dump (Texte)
        if command -v lynx >/dev/null 2>&1; then
            lynx -dump -nolist "page_temp.html" > "../dumps-text/${LANGUE}/${LANGUE}-${compteur}.txt"
        else
            sed 's/<[^>]*>/ /g' "page_temp.html" > "../dumps-text/${LANGUE}/${LANGUE}-${compteur}.txt"
        fi

        # 3. Compte mots
        nb_mots=$(wc -w < "../dumps-text/${LANGUE}/${LANGUE}-${compteur}.txt")

        # 4. Contexte
        if [ -n "$MOT" ]; then
            grep -i -C 2 "$MOT" "../dumps-text/${LANGUE}/${LANGUE}-${compteur}.txt" > "../contextes/${LANGUE}/${LANGUE}-${compteur}.txt"
        fi
    fi

    # -- D. Écriture HTML avec les LIENS --
    echo "                <tr>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$compteur</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$code_http</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$encodage</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$nb_mots</td>" >> "$FICHIER_HTML"
    echo "                    <td><a href=\"$line\" target=\"_blank\">Lien</a></td>" >> "$FICHIER_HTML"
    
    # Voici les 3 nouvelles colonnes avec liens relatifs
    echo "                    <td style=\"text-align:center\"><a href=\"../idoine/${LANGUE}/${LANGUE}-${compteur}.html\" class=\"button is-small is-link is-outlined\">html</a></td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\"><a href=\"../dumps-text/${LANGUE}/${LANGUE}-${compteur}.txt\" class=\"button is-small is-info is-outlined\">txt</a></td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\"><a href=\"../contextes/${LANGUE}/${LANGUE}-${compteur}.txt\" class=\"button is-small is-primary is-outlined\">contexte</a></td>" >> "$FICHIER_HTML"
    
    echo "                </tr>" >> "$FICHIER_HTML"

    echo "Url $compteur traitée ($code_http)"
    compteur=$((compteur + 1))

done < "$FICHIER_URLS"

# Fermeture HTML
echo "            </tbody>" >> "$FICHIER_HTML"
echo "        </table>" >> "$FICHIER_HTML"
echo "    </div>" >> "$FICHIER_HTML"
echo "</section>" >> "$FICHIER_HTML"
echo "</body></html>" >> "$FICHIER_HTML"

rm -f page_temp.html page_temp_utf8.html

echo "Terminé ! Fichier généré : $FICHIER_HTML"