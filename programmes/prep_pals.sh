#!/bin/bash

# 1. Vérification
if [ $# -ne 1 ]; then
    echo "Usage: ./prep_pals.sh <langue>"
    exit 1
fi

LANGUE=$1
INPUT_DIR="../dumps-text/${LANGUE}"
OUTPUT_DIR="../pals/${LANGUE}"

# Création du dossier de sortie
mkdir -p "$OUTPUT_DIR"

if [ ! -d "$INPUT_DIR" ]; then
    echo "Erreur : Le dossier $INPUT_DIR n'existe pas."
    exit 1
fi

echo "Préparation des fichiers pour PALS (Tokenisation avec Python)..."

# Boucle sur les fichiers
for file in "$INPUT_DIR"/*.txt; do
    if [ -s "$file" ]; then
        filename=$(basename "$file")
        
        # --- CORRECTION PYTHON ---
        # Au lieu d'utiliser 'tr' qui plante sur Mac, on utilise Python.
        # 1. On lit le fichier en ignorant les erreurs d'encodage.
        # 2. .split() coupe automatiquement le texte à chaque espace ou saut de ligne.
        # 3. .join('\n') recolle tout avec un mot par ligne.
        
        python3 -c "
import sys
try:
    # Lecture tolérante aux erreurs
    text = sys.stdin.buffer.read().decode('utf-8', errors='ignore')
    # Découpage (tokenisation) simple par espace
    tokens = text.split()
    # Affichage un mot par ligne
    print('\n'.join(tokens))
except Exception as e:
    pass
" < "$file" > "$OUTPUT_DIR/$filename"

    fi
done

echo "Fichiers prêts dans : $OUTPUT_DIR"