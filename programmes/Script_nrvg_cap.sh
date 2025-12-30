#!/bin/bash


URLS=$1
SORTIE="resultats_norvegien.html"
LANGUE="norvégien"

MOT_REGEX="(flåte|flåten|flåter|flåtene)"

#Verification 

if [ $# -ne 1 ]; then
    echo "Usage : $0 fichier_urls.txt"
    exit 1
fi

mkdir -p html txt concordances logs


echo "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>Résultats – $LANGUE</title>
<style>table {border-collapse: collapse; width: 100%;} th, td {border: 1px solid #ddd; padding: 8px;} tr:nth-child(even){background-color: #f2f2f2;} th {background-color: #4CAF50; color: white;}</style>
</head><body>" > "$SORTIE"

echo "<h1>Projet Corpus : Mot « flåte » ($LANGUE)</h1>" >> "$SORTIE"

echo "<table><tr>
<th>ID</th><th>URL</th><th>Code</th><th>Encodage</th><th>Occurrences</th><th>Contextes</th><th>Bigrammes</th><th>Dumps</th>
</tr>" >> "$SORTIE"

compteur=1


while read -r url; do
    echo "Traitement [$compteur] : $url"
   
    base="page_$compteur"
    
  
    domain=$(echo "$url" | awk -F/ '{print $3}')
    curl -s -L -o "logs/robots_$domain.txt" "http://$domain/robots.txt"

  
    code_http=$(curl -L -s -w "%{http_code}" -o "html/$base.html" "$url")

    
    if [ "$code_http" != "200" ]; then
        echo "<tr><td>$compteur</td><td>$url</td><td>$code_http</td><td colspan='5'>Erreur</td></tr>" >> "$SORTIE"
        ((compteur++))
        continue
    fi

   
    charset=$(file -bi "html/$base.html" | sed -n 's/.*charset=\(.*\)/\1/p' | tr '[:upper:]' '[:lower:]')
    
    if [[ "$charset" == *"utf-8"* || "$charset" == *"ascii"* ]]; then
        lynx -dump -nolist "html/$base.html" > "txt/$base.txt"
    else
     
        iconv -f "$charset" -t UTF-8 "html/$base.html" 2>/dev/null | lynx -dump -nolist -stdin > "txt/$base.txt" || echo "Erreur conversion" > "txt/$base.txt"
    fi


    nb_occ=$(egrep -i -o "\b$MOT_REGEX\b" "txt/$base.txt" | wc -l)

  
    egrep -i -C 2 "\b$MOT_REGEX\b" "txt/$base.txt" | \
    sed -E "s/($MOT_REGEX)/<b style='color:red; background:yellow'>\1<\/b>/Ig" > "concordances/$base.html"


    tr -sc '[:alpha:]' '\n' < "txt/$base.txt" | tr '[:upper:]' '[:lower:]' > "txt/$base.words"
    tail -n +2 "txt/$base.words" > "txt/$base.next"
    paste "txt/$base.words" "txt/$base.next" | sort | uniq -c | sort -rn | head -n 5 > "txt/$base.bigrams"
    
    
    bigrams_html=$(sed ':a;N;$!ba;s/\n/<br>/g' "txt/$base.bigrams")


    echo "<tr>
        <td>$compteur</td>
        <td><a href=\"$url\">Lien</a></td>
        <td>$code_http</td>
        <td>$charset</td>
        <td>$nb_occ</td>
        <td><a href=\"concordances/$base.html\">Voir</a></td>
        <td><small>$bigrams_html</small></td>
        <td><a href=\"html/$base.html\">HTML</a> / <a href=\"txt/$base.txt\">TXT</a></td>
    </tr>" >> "$SORTIE"

    ((compteur++))

done < "$URLS"

echo "</table></body></html>" >> "$SORTIE"