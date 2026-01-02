#!/bin/bash

#Pour vérifier que l'utilisateur a bien entré un argument
if [ $# -ne 1 ]
	then
	echo "Ce programme demande un argument."
	exit
fi

LANGUE=$1
compteur=1

# Définition des chemins (Respect de l'arborescence)
FICHIER_URLS="../URLs/${LANGUE}_url.txt"
DOSSIER_IDOINE="../idoine/${LANGUE}"
FICHIER_HTML="../tableaux/${LANGUE}_site.html"

# Vérification que le fichier d'URLs existe
if [ ! -f "$FICHIER_URLS" ]; then
    echo "Erreur : Le fichier $FICHIER_URLS est introuvable."
    exit 1
fi


# Écriture de l'en-tête HTML
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
        
        /* --- STYLE DU TABLEAU DYNAMIQUE --- */
        .table-epure { 
            width: 100%; 
            border-collapse: collapse; 
            background-color: #fff; 
            /* On laisse le navigateur calculer les largeurs selon le contenu */
            table-layout: auto; 
        }
        
        .table-epure th, .table-epure td { 
            border: 2px solid #1e3a8a; 
            padding: 12px 15px; 
            color: #000; 
            vertical-align: middle;
        }

        .table-epure th { 
            background-color: #f8f9fa; 
            font-weight: bold; 
            border-bottom: 3px solid #1e3a8a; 
            text-align: center; 
            /* MODIFICATION CRUCIALE : */
            /* Empêche le texte des titres de passer à la ligne */
            white-space: nowrap; 
        }

        .table-epure tr:hover { background-color: #eef2ff; }

        /* Gestion de la colonne URL pour qu'elle n'explose pas le tableau */
        /* On cible la dernière colonne (celle des URL) */
        .table-epure td:last-child {
            word-break: break-all; /* Force la coupure des liens très longs */
            min-width: 300px; /* Largeur minimale pour rester lisible */
        }

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

# Boucle de traitement ligne par ligne
echo "Traitement des URLs en cours..."


while read -r line;
do
	#pour un des lien on a un soucis de redirection, donc on ajoute -L, avec -I on ne récupère que l'entête du site
	# -s pour ne pas avoir la barre de progression, -o /dev/null pour récupérer le contenu de la page dans un fichier qui n'existe pas, donc on ne garde que le -w
	code=$(curl -s -I -L -o /dev/null -w "%{http_code}" "$line")

	#utiliser plusieur curl faisait bloquer wikimedia car trop de requêtes, j'en utilise donc seulement 1 que je met dans une variable contenu
	contenu=$(curl -s -L "$line")
	#on stock chaque page dans le dossier idoine, avec un sous dossier par langue. Grace a notre variable "LANGUE" on peut directement naviguer entre ces dossiers sans avoir à spécifier le chemin en argument
	echo "$contenu" > "../idoine/${LANGUE}/${LANGUE}${compteur}_page.txt"


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

	if [[ "${encodage,,}" == *"utf-8"* ]] ; then
			echo "$contenu" | lynx -stdin -dump -nolist > "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt"
			#en fonction de la langue le mot cherché est différent
			if [[ $LANGUE == "fr" ]]; then
				mot="flotte"
			elif [[ $LANGUE == "ang" ]]; then
				mot="fleet"
			elif [[ $LANGUE == "nrvg" ]]; then
				mot=""
			#si la langue n'est pas une des langues que nous étudions, on affiche un message d'erreur
			else
				echo "Le langage choisi n'est pas reconnu."
			fi
			#on extrait les contexte autour des mots
			egrep -i -C 2 "$mot" "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt" > "../contextes/${LANGUE}/${LANGUE}${compteur}_contexte.txt"
		#si l'encodage n'est pas UTF-8
	else
		#on trouve l'encodage pas en UTF-8
		encodage_autre=$(file -b --mime-encoding "../idoine/${LANGUE}/${LANGUE}${compteur}_page.txt")
		echo "URL $compteur : Encodage autre que UTF-8 : $encodage_autre"
		if [[ "$encodage_autre" != "binary" && "$encodage_autre" != "unknown"* ]]; then
            iconv -f "$encodage_autre" -t utf-8 "../idoine/${LANGUE}/${LANGUE}${compteur}_page.txt" > "../idoine/${LANGUE}/${LANGUE}${compteur}_page.tmp"
            #on remplace l'ancien fichier par celui qui vient de réencoder
			mv "../idoine/${LANGUE}/${LANGUE}${compteur}_page.tmp" "../idoine/${LANGUE}/${LANGUE}${compteur}_page.txt"
			echo "Fichier URL $compteur converti de $encodage_autre vers UTF-8"
			encodage="$encodage_autre (converti)"
			lynx -dump -nolist "../idoine/${LANGUE}/${LANGUE}${compteur}_page.txt" > "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt"
			egrep -i -C 2 "$mot" "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt" > "../contextes/${LANGUE}/${LANGUE}${compteur}_contexte.txt"
		else
		echo "Encodage non reconnu, pas d'extraction de contextes"
		fi
	fi

	mots=$(echo "$contenu"| wc -w)


    { echo "                <tr>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$compteur</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$code_http</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$encodage</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$nb_mots</td>" >> "$FICHIER_HTML"
    # La colonne URL n'a pas de style spécial ici, c'est le CSS global qui gère la coupe
    echo "                    <td><a href=\"$line\" target=\"_blank\">$line</a></td>" >> "$FICHIER_HTML"
    echo "                </tr>" } >> "$FICHIER_HTML"

    echo "Url $compteur traité"

	#incrémentation compteur
	compteur=$((compteur + 1))
	#pour éviter de recevoir le code 429 "too many request" j'impose un temps de latence d'une seconde entre les requêtes
	sleep 1
done < "../URLs/${LANGUE}_url.txt";

# 5. Fermeture du fichier HTML
echo "            </tbody>" >> "$FICHIER_HTML"
echo "        </table>" >> "$FICHIER_HTML"
echo "    </div>" >> "$FICHIER_HTML"
echo "</section>" >> "$FICHIER_HTML"
echo "</body></html>" >> "$FICHIER_HTML"

echo "Terminé ! Fichier généré : $FICHIER_HTML"
