#!/usr/bin/bash

#Pour vérifier que l'utilisateur a bien entré un argument
if [ $# -ne 1 ]
	then
	echo "Ce programme demande un argument."
	exit
fi

LANGUE=$1

#Définition des chemins (Respect de l'arborescence)
FICHIER_URLS="../URLs/${LANGUE}_url.txt"
DOSSIER_IDOINE="../aspirations/${LANGUE}"
FICHIER_HTML="../tableaux/${LANGUE}_site.html"

# on crée un sous dossier par langue dans chaque dossier pour ne pas mélanger tous les fichiers si on lance le programme plusieurs fois sur plusieurs langues
mkdir -p "../aspirations/${LANGUE}" "../dumps-text/${LANGUE}" "../contextes/${LANGUE}"


# Vérification que le fichier d'URLs existe
if [ ! -f "$FICHIER_URLS" ]; then
    echo "Le fichier $FICHIER_URLS est introuvable."
    exit 1
fi

#initialisation d'une variable comptant les lignes
compteur=1

#on crée une variable qui va stocker nos données extraites dans un tableau pour les traiter ensuite
TSV+=$'Ligne\tCode_HTTP\tEncodage\tMots\tURL\tAspiration\tDump Initial\tDump UTF-8\tContexte\n'

echo "Traitement des urls..."
while read -r line;
do
	#pour un des lien on a un soucis de redirection, donc on ajoute -L, avec -I on ne récupère que l'entête du site
	# -s pour ne pas avoir la barre de progression, -o /dev/null pour récupérer le contenu de la page dans un fichier qui n'existe pas, donc on ne garde que le -w
	code=$(curl -s -I -L -o /dev/null -w "%{http_code}" "$line")

	#utiliser plusieur curl faisait bloquer wikimedia car trop de requêtes, j'en utilise donc seulement 1 que je met dans une variable contenu
	contenu=$(curl -s -L "$line")
	#on stock chaque page dans le dossier aspirations, avec un sous dossier par langue. Grace a notre variable "LANGUE" on peut directement naviguer entre ces dossiers sans avoir à spécifier le chemin en argument
	echo "$contenu" > "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html"


	encodage=$(echo "$contenu" | grep -ioP "charset=[\"']?\K[\w-]+" | head -n 1)
	if [ -z "$encodage" ]
		then
		encodage=$(curl -s -I -L "$line" | grep -i 'content-type' | sed 's/.*charset=//I' | tr -d '\r')
	fi

	#dans le cas la variable encodage est vide, au lieu de l'afficher tel quel on la remplie par "absence d'encodage"
	if [ -z "$encodage" ]
		then
		encodage="Absence d'encodage"
	fi
	#en fonction de la langue le mot cherché est différent
	if [[ $LANGUE == "fr" ]]; then
		mot="flotte"
	elif [[ $LANGUE == "ang" ]]; then
		mot="fleet"
	elif [[ $LANGUE == "nrvg" ]]; then
		mot="flåte"
	#si la langue n'est pas une des langues que nous étudions, on affiche un message d'erreur
	else
		echo "Le langage choisi n'est pas reconnu."
	fi
	if [[ "${encodage,,}" == *"utf-8"* ]] ; then
			echo "$contenu" | lynx -stdin -dump -nolist > "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt"
			#on extrait les contexte autour des mots
			egrep -i -C 2 "$mot" "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt" > "../contextes/${LANGUE}/${LANGUE}${compteur}_contexte.txt"
		#si l'encodage n'est pas UTF-8
	else
		#on trouve l'encodage pas en UTF-8
		encodage_autre=$(file -b --mime-encoding "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html")
		echo "URL $compteur : Encodage autre que UTF-8 : $encodage_autre"
		if [[ "$encodage_autre" != "binary" && "$encodage_autre" != "unknown"* ]]; then
            lynx -dump -nolist "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html" > "../dumps-text/${LANGUE}/${LANGUE}${compteur}_initial.txt"
            iconv -f "$encodage_autre" -t utf-8 "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html" > "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.tmp"
            #on remplace l'ancien fichier par celui qui vient de réencoder
			mv "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.tmp" "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html"
			echo "Fichier URL $compteur converti de $encodage_autre vers UTF-8"
			encodage="$encodage_autre (converti)"
			lynx -dump -nolist "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html" > "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt"
			egrep -i -C 2 "$mot" "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt" > "../contextes/${LANGUE}/${LANGUE}${compteur}_contexte.txt"
		else
		echo "Encodage non reconnu, pas d'extraction de contextes"
		fi
	fi

	mots=$(echo "$contenu"| wc -w)

	lien_asp="../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html"
    lien_dump="../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt"
    lien_dumpinitial="../dumps-text/${LANGUE}/${LANGUE}${compteur}_initial.txt"
    if [ ! -f "$lien_dumpinitial" ]; then
        lien_dumpinitial="   "
    fi
    lien_ctx="../contextes/${LANGUE}/${LANGUE}${compteur}_contexte.txt"

	#on ajoute nos infos dans la varibale TSV
	TSV+="${compteur}"$'\t'"${code}"$'\t'"${encodage}"$'\t'"${mots}"$'\t'"${line}"$'\t'"${lien_asp}"$'\t'"${lien_dumpinitial}"$'\t'"${lien_dump}"$'\t'"${lien_ctx}"$'\n'
	echo "Url $compteur traité"

	#incrémentation compteur
	compteur=$((compteur + 1))
	#pour éviter de recevoir le code 429 "too many request" j'impose un temps de latence d'une seconde entre les requêtes
	sleep 1
done < "../URLs/${LANGUE}_url.txt";

echo "Création du fichier html..."
{
echo "<html>"
echo "  <head>"
echo "          <meta charset=\"UTF-8\" />"
echo "           <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bulma@1.0.4/css/bulma.min.css\" />"
echo "          <style>
          body {
            font-family: Arial, sans-serif; }
          </style>"
echo "  </head>"
echo "  <body>"
echo "   <article class=\"message is-dark is small\">
  <div class=\"message-body\">
    Bienvenue sur ce site. Vous y trouverez les résultats des extractions de données du mini-projet 1.
  </div>
</article>
<div class=\"container\">
<h2 class=\"title is-2 has-text-centered\">Tableaux analyse URLS</h2>"
echo "      <table class=\"table is-striped is-fullwidth is-bordered is-hoverable is-narrow\">"

#on précise que les colonnes sont marquées par des tabulation avec IFS=$"\t"
echo "$TSV" | while IFS=$'\t' read -r -a colonne;
do
	if [[ "${colonne[0]}" == "Ligne" ]]; then
        echo "          <thead><tr class=\"has-background-light\">"
        for col in "${colonne[@]}";
        do
          echo "                <th>${col}</th>"
        done
        echo "          </tr></thead><tbody>"
	else
        echo "          <tr>"
        col_idx=0
        for col in "${colonne[@]}"; do
            if [[ $col_idx -ge 5 ]]; then
                # On affiche uniquement le nom du fichier (ex: fr1_page.txt)
                nom_fichier=$(basename "${col}")
                echo "                <td><a href=\"${col}\" target=\"_blank\">${nom_fichier}</a></td>"
            else
                echo "                <td>${col}</td>"
            fi
            col_idx=$((col_idx + 1))
        done
        echo "          </tr>"
    fi
done

echo "      </table>"
echo " 		</div>"
echo "  </body>"
echo "</html>"
} >"../tableaux/${LANGUE}_site.html"

echo "Fichier crée à : ../tableaux/${LANGUE}_site.html"

#creation du wordcloud

## on crée un fichier temporaire qui stock tous les texte d'une langue pour faire le wordscloud sur tous les contextes extraits
cat ../contextes/${LANGUE}/*.txt > ../contextes/${LANGUE}/total_${LANGUE}.tmp
if [ -s "../contextes/${LANGUE}/total_${LANGUE}.tmp" ]; then
    wordcloud_cli --text "../contextes/${LANGUE}/total_${LANGUE}.tmp" \
		--imagefile "../images/nuage_${LANGUE}.png" \
		--stopwords "../stopwords/stopwords-${LANGUE}.txt" \
		--mask "../images/bateau.png" \
		--scale 3 \
        --background white \
        --contour_width 3
	echo "Nuage de mot crée à "../images/nuage_${LANGUE}.png"
else
	echo "Pas assez de texte pour générer un nuage de mots pour ${LANGUE}"
fi
