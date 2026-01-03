#!/bin/bash

# 1. Vérification de l'argument
if [ $# -ne 1 ]; then
    echo "Usage: ./script_itrameur.sh <langue>"
    echo "Exemple: ./script_itrameur.sh nrvg"
    exit 1
fi

LANGUE=$1
DOSSIER_DUMPS="../dumps-text/${LANGUE}"
OUTPUT="../itrameur/${LANGUE}_corpus.txt"

# On crée le dossier itrameur s'il n'existe pas
mkdir -p "../itrameur"

# Vérification que le dossier des dumps existe
if [ ! -d "$DOSSIER_DUMPS" ]; then
    echo "Erreur : Le dossier $DOSSIER_DUMPS n'existe pas. Lancez d'abord le script principal."
    exit 1
fi

echo "Création du corpus pour iTrameur : $OUTPUT"

# Début du fichier XML
echo "<lang=\"$LANGUE\">" > "$OUTPUT"

# On boucle sur chaque fichier texte
for filepath in "$DOSSIER_DUMPS"/*.txt; do
    # On vérifie que le fichier existe
    if [ -f "$filepath" ]; then
        filename=$(basename "$filepath")
        
        # --- CORRECTION ICI ---
        # 1. On lit le fichier
        # 2. iconv -c : On nettoie les caractères invalides qui font planter sed sur Mac
        # 3. tr -d '\r' : On vire les retours chariot Windows au cas où
        content=$(cat "$filepath" | iconv -f utf-8 -t utf-8 -c | tr -d '\r')
        
        # 4. Maintenant sed ne plantera plus car le texte est propre
        content=$(echo "$content" | sed 's/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g')

        # On écrit la structure XML
        echo "<page=\"$filename\">" >> "$OUTPUT"
        echo "<text>" >> "$OUTPUT"
        echo "$content" >> "$OUTPUT"
        echo "</text>" >> "$OUTPUT"
        echo "</page>" >> "$OUTPUT"
    fi
done

# Fin du fichier XML
echo "</lang>" >> "$OUTPUT"

echo "Terminé ! Le fichier est prêt ici : $OUTPUT"