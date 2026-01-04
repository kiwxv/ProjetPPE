#!/usr/bin/bash

if [ $# -ne 1 ]; then
    echo "Ce programme demande un argument (fr, ang, nrvg)."
    exit 1
fi

LANGUE=$1

#Définition des chemins (Respect de l'arborescence)
FICHIER_URLS="../URLs/${LANGUE}_url.txt"
FICHIER_HTML="../tableaux/${LANGUE}_site.html"

# on crée un sous dossier par langue dans chaque dossier pour ne pas mélanger tous les fichiers si on lance le programme plusieurs fois sur plusieurs langues
mkdir -p "../aspirations/${LANGUE}" "../dumps-text/${LANGUE}" "../contextes/${LANGUE}" "../images" "../contextes/bigrammes" "../aspirations/robot${LANGUE}"
rm -rf "../dumps-text/${LANGUE}/"* rm -rf "../contextes/${LANGUE}/"*

# Vérification que le fichier d'URLs existe
if [ ! -f "$FICHIER_URLS" ]; then
    echo "Erreur : Le fichier $FICHIER_URLS est introuvable."
    exit 1
fi

#en fonction de la langue le mot cherché est différent
if [[ $LANGUE == "fr" ]]; then
    mot="flottes?"
elif [[ $LANGUE == "ang" ]]; then
    mot="fleets?"
elif [[ $LANGUE == "nrvg" ]]; then
    mot="fl(å|&aring;|&#229;|.{1,2})t"
else
    #si la langue n'est pas une des langues que nous étudions, on affiche un message d'erreur
    echo "Le langage choisi n'est pas reconnu."
    exit 1
fi

#on vide le fichier bigramme pour qu'il n'accumule pas les bigrammes à chaque fois qu'on lance le script
> "../contextes/bigrammes/bigrammes_${LANGUE}.txt"
cat <<EOF > "$FICHIER_HTML"
<!DOCTYPE HTML>
<html>
<head>
    <title>Tableau $LANGUE - Projet PPE</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no" />
    <link rel="stylesheet" href="../assets/css/main.css" />
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@1.0.4/css/bulma.min.css" />
    <noscript><link rel="stylesheet" href="../assets/css/noscript.css" /></noscript>
    <style>
        body { background-color: #ffffff; color: #000; }
        #main { background-color: white; padding: 2em; }
        #wrapper { width: 100%; max-width: none !important; }
        .title { color: #1e3a8a !important; }
        .table-container { overflow-x: auto; margin-top: 20px; }
        .table-epure { width: 100%; border-collapse: collapse; background-color: #fff; table-layout: auto; margin-bottom: 3em; min-width: 1000px;}
        .table-epure th, .table-epure td { border: 2px solid #1e3a8a; padding: 12px 15px; color: #000; vertical-align: middle; font-family: sans-serif; font-size: 0.9em; }
        .table-epure th { background-color: #f8f9fa; font-weight: bold; border-bottom: 3px solid #1e3a8a; text-align: center; white-space: nowrap; }
        .table-epure tr:hover { background-color: #eef2ff; }
        .table-epure td:nth-child(5) { word-break: break-all; min-width: 200px; }
        .button.is-small { font-size: 0.8rem; margin: 2px; }
    </style>
</head>
<body class="is-preload">
    <div id="wrapper">
        <header id="header"><a href="../index.html" class="logo">Flotte</a></header>
        <nav id="nav">
            <ul class="links">
                <li><a href="../index.html">Accueil</a></li>
                <li class="active"><a href="../tableaux.html">Tableaux</a></li>
                <li><a href="../scripts.html">Scripts</a></li>
                <li><a href="../nuages.html">Nuages de mots</a></li>
                <li><a href="../itrameur.html">iTrameur</a></li>
            </ul>
            <ul class="icons">
                <li><a href="https://github.com/kiwxv/ProjetPPE" class="icon brands fa-github"><span class="label">GitHub</span></a></li>
            </ul>
        </nav>
        <div id="main">
            <section class="post">
                <header class="major">
                    <h1>Tableau de données</h1>
                    <p>Tableau crée par Capucine Leclerc et Lucy-Lou Agard. <br> Langue : <span style="text-transform:uppercase; color:#1e3a8a; font-weight:bold;">$LANGUE</span></p>
                </header>
                <div class="table-container">
                    <table class="table-epure">
                        <thead>
                            <tr>
                                <th>Ligne</th>
                                <th>Code HTTP</th>
                                <th>Encodage</th>
                                <th>Mots</th>
                                <th>URL</th>
                                <th>Aspirations / Dumps / Contextes / Bigramme / Robot.txt</th>
                            </tr>
                        </thead>
                        <tbody>
EOF

#créa concordancier
#avant la boucle while, on initialise le fichier HTML du concordancier
FICHIER_CONCO="../concordances/concordancier_${LANGUE}.html"

cat <<EOF > "$FICHIER_CONCO"
<!DOCTYPE HTML>
<html>
<head>
    <meta charset="utf-8" />
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@1.0.4/css/bulma.min.css" />
    <style>
        .conco-table { width: 100%; border-collapse: collapse; }
        .conco-table td, .conco-table th { padding: 8px; border: 1px solid #dbdbdb; }
        .gauche { text-align: right; width: 45%; }
        .pivot { text-align: center; width: 10%; font-weight: bold; color: green; background-color: #fff9f9; }
        .droite { text-align: left; width: 45%; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="title is-3 has-text-centered">Concordancier : $LANGUE</h1>
        <table class="conco-table">
            <thead>
                <tr>
                    <th class="gauche">Contexte Gauche</th>
                    <th class="pivot">Mot</th>
                    <th class="droite">Contexte Droit</th>
                </tr>
            </thead>
            <tbody>
EOF

#initialisation d'une variable comptant les lignes
compteur=1
echo "Traitement des urls..."
while read -r line; do
	#pour un des lien on a un soucis de redirection, donc on ajoute -L, avec -I on ne récupère que l'entête du site
	# -s pour ne pas avoir la barre de progression, -o /dev/null pour récupérer le contenu de la page dans un fichier qui n'existe pas, donc on ne garde que le -w
    code=$(curl -s -I -L -o /dev/null -w "%{http_code}" "$line")

    #utiliser plusieur curl faisait bloquer wikimedia car trop de requêtes, j'en utilise donc seulement 1 que je met dans une variable contenu
    contenu=$(curl -s -L "$line")
	#on stock chaque page dans le dossier aspirations, avec un sous dossier par langue. Grace a notre variable "LANGUE" on peut directement naviguer entre ces dossiers sans avoir à spécifier le chemin en argument
    echo "$contenu" > "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html"

    encodage=$(echo "$contenu" | grep -ioP "charset=[\"']?\K[\w-]+" | head -n 1)
    if [ -z "$encodage" ]; then
        encodage=$(curl -s -I -L "$line" | grep -i 'content-type' | sed 's/.*charset=//I' | tr -d '\r')
    fi

	#dans le cas la variable encodage est vide, au lieu de l'afficher tel quel on la remplie par "absence d'encodage"
    if [ -z "$encodage" ]; then
        encodage="Absence d'encodage"
    fi

    if [[ "${encodage,,}" == *"utf-8"* ]] ; then
        echo "$contenu" | lynx -stdin -dump -nolist > "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt"
        #on extrait les contexte autour des mots
        egrep -i -C 2 "$mot" "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt" > "../contextes/${LANGUE}/${LANGUE}${compteur}_contexte.txt"
    #si l'encodage n'est pas UTF-8
    else
        encodage_autre=$(file -b --mime-encoding "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html")
		echo "URL $compteur : Encodage autre que UTF-8 : $encodage_autre"
        if [[ "$encodage_autre" != "binary" && "$encodage_autre" != "unknown"* ]]; then
            lynx -dump -nolist "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html" > "../dumps-text/${LANGUE}/${LANGUE}${compteur}_initial.txt"
            iconv -f "$encodage_autre" -t utf-8 "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html" > "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.tmp"
            #on remplace l'ancien fichier par celui qui vient de réencoder
            mv "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.tmp" "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html"
			echo "Fichier URL $compteur converti de $encodage_autre vers UTF-8"
            encodage="$encodage_autre (conv)"
            lynx -dump -nolist "../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html" > "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt"
            egrep -i -C 2 "$mot" "../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt" > "../contextes/${LANGUE}/${LANGUE}${compteur}_contexte.txt"
		else
		echo "Encodage non reconnu, pas d'extraction de contextes"
        fi
    fi

    lien_asp="../aspirations/${LANGUE}/${LANGUE}${compteur}_page.html"
    lien_dump="../dumps-text/${LANGUE}/${LANGUE}${compteur}.txt"
    lien_dumpinitial="../dumps-text/${LANGUE}/${LANGUE}${compteur}_initial.txt"
    if [ ! -f "$lien_dumpinitial" ]; then
        lien_dumpinitial="   "
    fi
    lien_ctx="../contextes/${LANGUE}/${LANGUE}${compteur}_contexte.txt"

    #on récupère si le fichier dump a bien pu être crée
    if [ -f "$lien_dump" ]; then
        #récupération des bigrammes, mot précédant et suivant notre mot
        grep -ioP "\w+\W+$mot" "$lien_dump" >> "../contextes/bigrammes/bigrammes_${LANGUE}.txt"
        grep -ioP "$mot\W+\w+" "$lien_dump" >> "../contextes/bigrammes/bigrammes_${LANGUE}.txt"
        bigramme_html=$(grep -ioP "$mot\W+\w+" "$lien_dump" | head -n 1)
        bigramme_html=$(grep -ioP "\w+\W+$mot" "$lien_dump" | head -n 1)
        mots=$(wc -w < "$lien_dump")
        #récupérations info concordancier
        grep -ioP "(\w+\W+){0,4}$mot(\W+\w+){0,4}" "$lien_dump" | while read -r line_conco; do
            #sépare le gauche le pivot et le droit
            #utilise sed pour isoler ce qui est avant et après le mot
            gauche=$(echo "$line_conco" | sed -E "s/(.*)($mot)(.*)/\1/I")
            pivot=$(echo "$line_conco" | sed -E "s/(.*)($mot)(.*)/\2/I")
            droite=$(echo "$line_conco" | sed -E "s/(.*)($mot)(.*)/\3/I")
            echo "<tr><td class='gauche'>$gauche</td><td class='pivot'>$pivot</td><td class='droite'>$droite</td></tr>" >> "$FICHIER_CONCO"
        done
    else
        bigramme_html="-"
        mots="0"
    fi

    #récupération du fichier robot.txt pour chaque site
    #puisque robot.txt est un fichier présent à la racine d'un site, on en peut pas garder nos url comme ils sont pour l'instant, il faut récupérer le domaine du site
    domaine=$(echo "$line" | cut -d'/' -f1-3)
    #pour le réutiliser ensuite dans le nom du fichier, on crée une version "clean" du nom de domaine qui ne posera pas de soucis
    domaine_clean=$(echo "$domaine" | sed 's/[/:]/_/g')
    #puisque certains sites auront le même robot.txt, on verifie d'abord que le fichier n'est pas déjà téléchargé avant d'en ajouter un nouveau
    if [ ! -f "../aspirations/robot${LANGUE}/robots_${domaine_clean}.txt" ]; then
        curl -s -f "$domaine/robots.txt" > "../aspirations/robot${LANGUE}/robots_${domaine_clean}.txt"
    fi


    #on ajoute nos infos dans la varibale TSV
	TSV+="${compteur}"$'\t'"${code}"$'\t'"${encodage}"$'\t'"${mots}"$'\t'"${line}"$'\t'"${lien_asp}"$'\t'"${lien_dumpinitial}"$'\t'"${lien_dump}"$'\t'"${lien_ctx}"$'\n'

    echo "                <tr>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$compteur</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$code</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$encodage</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$mots</td>" >> "$FICHIER_HTML"
    echo "                    <td><a href=\"$line\" target=\"_blank\">$line</a></td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">" >> "$FICHIER_HTML"
    echo "                        <a href=\"$lien_asp\" class=\"button is-small is-link is-outlined\">html</a>" >> "$FICHIER_HTML"
    if [ -f "$lien_dumpinitial" ]; then
        echo "                        <a href=\"$lien_dumpinitial\" class=\"button is-small is-warning is-outlined\">initial</a>" >> "$FICHIER_HTML"
    fi
    echo "                        <a href=\"$lien_dump\" class=\"button is-small is-info is-outlined\">txt</a>" >> "$FICHIER_HTML"
    echo "                        <a href=\"$lien_ctx\" class=\"button is-small is-primary is-outlined\">contexte</a>" >> "$FICHIER_HTML"
    echo "                        <a href=\"../contextes/bigrammes/bigrammes_${LANGUE}.txt\" class=\"button is-small is-primary is-outlined\">bigramme</a>" >> "$FICHIER_HTML"
    echo "                        <a href=\"../aspirations/robot${LANGUE}/robots_${domaine_clean}.txt\" class=\"button is-small is-primary is-outlined\">robot.txt</a>" >> "$FICHIER_HTML"
    echo "                    </td>" >> "$FICHIER_HTML"
    echo "                </tr>" >> "$FICHIER_HTML"

    echo "URL $compteur traitée ($code)"
    #incrémentation compteur
	compteur=$((compteur + 1))
	#pour éviter de recevoir le code 429 "too many request" on impose un temps de latence d'une seconde entre les requêtes
	sleep 1
done < "$FICHIER_URLS"
echo "Tableau créé à : $FICHIER_HTML"

cat <<EOF >> "$FICHIER_HTML"
                        </tbody>
                    </table>
                </div>
                <div style="text-align:center; margin-top:2em;">
                    <a href="../tableaux.html" class="button" style="background-color: #1e3a8a; color: #ffffff !important; border: none;">Retour au choix des langues</a>
                </div>
            </section>
        </div>
        <div id="copyright"><ul><li>&copy; Projet PPE</li></ul></div>
    </div>
</body>
</html>
EOF

echo "</tbody></table></div></body></html>" >> "$FICHIER_CONCO"
echo "Concordancier crée à $FICHIER_CONCO"
#creation du wordcloud
## on crée un fichier temporaire qui stock tous les texte d'une langue pour faire le wordscloud sur tous les contextes extraits

cat ../contextes/${LANGUE}/*.txt > "../contextes/total_global_${LANGUE}.txt"

if [ -s "../contextes/total_global_${LANGUE}.txt" ]; then
    wordcloud_cli --text "../contextes/total_global_${LANGUE}.txt" \
        --imagefile "../images/nuage_${LANGUE}.png" \
        --stopwords "../stopwords/stopwords-${LANGUE}.txt" \
        --mask "../images/bateau.png" \
        --scale 3 \
        --background white \
        --contour_width 0
    echo "Nuage de mots créé à ../images/nuage_${LANGUE}.png"
else
    echo "Pas assez de texte pour le nuage de mots."
fi
