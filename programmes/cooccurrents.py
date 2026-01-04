#!/usr/bin/env python3
import sys
import argparse
import glob
import re
from collections import Counter

# Ce script remplace PALS pour générer les données du Nuage de Mots.
# Il est insensible à la casse (Flåte = flåte) et nettoie la ponctuation.

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('files', nargs='+', help='Fichiers du corpus')
    parser.add_argument('--target', required=True, help='Le mot cible')
    # Options bidons pour ne pas faire planter si on utilise les commandes PALS
    parser.add_argument('--tool-emulation', required=False)
    args = parser.parse_args()

    target = args.target.lower()
    window = 10 # 10 mots avant, 10 mots après
    context_words = []
    
    print(f"--- Recherche de '{target}' ---", file=sys.stderr)

    # 1. Lecture de tous les fichiers
    all_words = []
    for file_pattern in args.files:
        for filename in glob.glob(file_pattern):
            try:
                with open(filename, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    # On nettoie tout ce qui n'est pas une lettre ou un chiffre
                    # pour éviter les problèmes de ponctuation collée
                    words = re.findall(r'\w+', content.lower())
                    all_words.extend(words)
            except Exception as e:
                pass

    print(f"Total mots lus : {len(all_words)}", file=sys.stderr)

    # 2. Récupération des cooccurrences
    found_count = 0
    for i, word in enumerate(all_words):
        if word == target:
            found_count += 1
            start = max(0, i - window)
            end = min(len(all_words), i + window + 1)
            # On prend le contexte (sauf le mot lui-même)
            context = all_words[start:i] + all_words[i+1:end]
            context_words.extend(context)

    print(f"Occurrences trouvées du pivot : {found_count}", file=sys.stderr)

    if found_count == 0:
        print("ATTENTION : Le mot pivot n'a pas été trouvé !", file=sys.stderr)

    # 3. Calcul et Affichage
    counter = Counter(context_words)
    
    # En-tête du tableau
    print("Mot\tFrequence")
    
    # On affiche le Top 50
    for word, count in counter.most_common(50):
        # On ignore les mots vides courants (optionnel mais mieux pour le nuage)
        stop_words = ['le', 'la', 'de', 'du', 'et', 'à', 'en', 'un', 'une', 'the', 'of', 'and', 'to', 'a', 'in', 'i', 'og', 'det', 'er', 'som', 'til', 'en', 'av', 'for', 'på', 'at']
        if word not in stop_words and len(word) > 2:
            print(f"{word}\t{count}")

if __name__ == "__main__":
    main()
