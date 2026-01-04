#!/bin/bash

# 1. Vérification de l'argument
if [ $# -ne 1 ]; then
    echo "Usage: ./script_itrameur.sh <langue>"
    exit 1
fi

LANGUE=$1
DOSSIER_DUMPS="../dumps-text/${LANGUE}"
OUTPUT="../itrameur/${LANGUE}_corpus.txt"

mkdir -p "../itrameur"

if [ ! -d "$DOSSIER_DUMPS" ]; then
    echo "Erreur : Le dossier $DOSSIER_DUMPS n'existe pas."
    exit 1
fi

echo "Création du corpus pour iTrameur : $OUTPUT"

# Début du XML
echo "<lang=\"$LANGUE\">" > "$OUTPUT"

# Boucle sur les fichiers
for filepath in "$DOSSIER_DUMPS"/*.txt; do
    if [ -s "$filepath" ]; then
        filename=$(basename "$filepath")
        
        # --- SOLUTION CIBLÉE ---
        # 1. Decode avec 'replace' -> Crée des 
        # 2. On remplace spécifiquement le motif "Flte" (et ses variantes) par "flåte"
        
        content=$(python3 -c "
import sys

# Lecture binaire
raw = sys.stdin.buffer.read()

# Décodage (les erreurs deviennent )
text = raw.decode('utf-8', errors='replace')

# --- RÉPARATIONS ---
# On cible le caractère de remplacement (Unicode \ufffd est le fameux )
text = text.replace('Fl\ufffdte', 'flåte')
text = text.replace('fl\ufffdte', 'flåte')
text = text.replace('Flte', 'flåte')
text = text.replace('flte', 'flåte')

# Au cas où il resterait l'ancienne erreur
text = text.replace('FlÂte', 'flåte')

# Nettoyage XML pour iTrameur
text = text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

print(text)
" < "$filepath")

        # Écriture dans le fichier final
        echo "<page=\"$filename\">" >> "$OUTPUT"
        echo "<text>" >> "$OUTPUT"
        echo "$content" >> "$OUTPUT"
        echo "</text>" >> "$OUTPUT"
        echo "</page>" >> "$OUTPUT"
    fi
done

# Fin du XML
echo "</lang>" >> "$OUTPUT"

echo "Terminé ! Le fichier est réparé."