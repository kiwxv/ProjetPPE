#!/bin/bash

# Vérification de l'argument
if [ $# -ne 1 ]; then
    echo "Usage: bash script_itrameur.sh <langue>"
    echo "Exemple: bash script_itrameur.sh fr"
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
    # [ -s ] vérifie que le fichier existe ET n'est pas vide (évite les bugs)
    if [ -s "$filepath" ]; then
        filename=$(basename "$filepath")
        
        # iconv -c : Enlève les caractères invalides
        # 2>/dev/null : Cache les erreurs "unexpected end of file" (accents coupés)
        # tr -d '\r' : Supprime les retours chariot Windows
        content=$(iconv -f utf-8 -t utf-8 -c "$filepath" 2>/dev/null | tr -d '\r')
        
        # Protection des balises XML pour iTrameur (<, >, &)
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
