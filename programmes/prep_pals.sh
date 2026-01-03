#!/bin/bash

# Vérification
if [ $# -ne 1 ]; then
    echo "Usage: ./preparation_pals.sh <langue>"
    exit 1
fi

LANGUE=$1
INPUT_DIR="../dumps-text/${LANGUE}"
OUTPUT_DIR="../pals/${LANGUE}"

mkdir -p "$OUTPUT_DIR"

echo "Préparation des fichiers pour PALS (Tokenisation)..."

for file in "$INPUT_DIR"/*.txt; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        # On prend le fichier et on nettoie la ponctuation basique 
        # On remplace les espaces par des retours à la ligne
        cat "$file" | tr -s '[:space:]' '\n' | sed '/^$/d' > "$OUTPUT_DIR/$filename"
    fi
done

echo "Fichiers prêts dans : $OUTPUT_DIR"