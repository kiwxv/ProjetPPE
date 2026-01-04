#!/bin/bash
export LC_ALL=C.UTF-8

# 1. Vérification de l'argument
if [ $# -ne 1 ]; then
    echo "Ce programme demande un argument (fr, ang, nrvg)."
    exit 1
fi

LANGUE=$1
compteur=1

# 2. Définition du mot clé
if [[ $LANGUE == "fr" ]]; then
    MOT="flotte"
elif [[ $LANGUE == "ang" ]]; then
    MOT="fleet"
elif [[ $LANGUE == "nrvg" ]]; then
    MOT="fl(å|&aring;|&#229;|.{1,2})t"
else
    MOT=""
    echo "Attention : Langue non reconnue."
fi

# 3. Création des dossiers
mkdir -p "../URLs"
mkdir -p "../tableaux"
mkdir -p "../idoine/${LANGUE}"
mkdir -p "../dumps-text/${LANGUE}"
mkdir -p "../contextes/${LANGUE}"

FICHIER_URLS="../URLs/${LANGUE}_url.txt"
FICHIER_HTML="../tableaux/${LANGUE}_site.html"

if [ ! -f "$FICHIER_URLS" ]; then
    echo "Erreur : Le fichier $FICHIER_URLS est introuvable."
    exit 1
fi

# 4. En-tête HTML (AVEC LE MENU ET LE DESIGN DU SITE)
echo "Création de l'en-tête HTML..."
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
        .title { color: #1e3a8a !important; }
        
        .table-epure { width: 100%; border-collapse: collapse; background-color: #fff; table-layout: auto; margin-bottom: 3em; }
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
                    <p>Langue : <span style="text-transform:uppercase; color:#1e3a8a; font-weight:bold;">$LANGUE</span></p>
                </header>

                <div class="table-container">
                    <table class="table-epure">
                        <thead>
                            <tr>
                                <th>Numéro</th>
                                <th>Code</th>
                                <th>Encodage</th>
                                <th>Mots</th>
                                <th>URL</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
EOF

# 5. Boucle
echo "Traitement des URLs pour le motif : $MOT"

while read -r line; do
    code_http=$(curl -s -L -o "page_temp.html" -w "%{http_code}" "$line")

    if [ ! -s "page_temp.html" ]; then
        code_http="ERR"
        encodage="inconnu"
        nb_mots="0"
    else
        encodage=$(file -b --mime-encoding "page_temp.html")
        if [[ "$encodage" != "utf-8" && "$encodage" != "us-ascii" ]]; then
            iconv -f "$encodage" -t utf-8 "page_temp.html" > "page_temp_utf8.html" 2>/dev/null
            if [ $? -eq 0 ]; then
                mv "page_temp_utf8.html" "page_temp.html"
                encodage="$encodage (conv)"
            fi
        fi

        cp "page_temp.html" "../idoine/${LANGUE}/${LANGUE}-${compteur}.html"

        if command -v lynx >/dev/null 2>&1; then
            lynx -dump -nolist "page_temp.html" > "../dumps-text/${LANGUE}/${LANGUE}-${compteur}.txt"
        else
            sed 's/<[^>]*>/ /g' "page_temp.html" > "../dumps-text/${LANGUE}/${LANGUE}-${compteur}.txt"
        fi

        nb_mots=$(wc -w < "../dumps-text/${LANGUE}/${LANGUE}-${compteur}.txt")

        if [ -n "$MOT" ]; then
            grep -E -i -C 2 "$MOT" "../dumps-text/${LANGUE}/${LANGUE}-${compteur}.txt" > "../contextes/${LANGUE}/${LANGUE}-${compteur}.txt"
        fi
    fi

    echo "                <tr>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$compteur</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$code_http</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$encodage</td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">$nb_mots</td>" >> "$FICHIER_HTML"
    echo "                    <td><a href=\"$line\" target=\"_blank\">$line</a></td>" >> "$FICHIER_HTML"
    echo "                    <td style=\"text-align:center\">" >> "$FICHIER_HTML"
    echo "                        <a href=\"../idoine/${LANGUE}/${LANGUE}-${compteur}.html\" class=\"button is-small is-link is-outlined\">html</a>" >> "$FICHIER_HTML"
    echo "                        <a href=\"../dumps-text/${LANGUE}/${LANGUE}-${compteur}.txt\" class=\"button is-small is-info is-outlined\">txt</a>" >> "$FICHIER_HTML"
    echo "                        <a href=\"../contextes/${LANGUE}/${LANGUE}-${compteur}.txt\" class=\"button is-small is-primary is-outlined\">contexte</a>" >> "$FICHIER_HTML"
    echo "                    </td>" >> "$FICHIER_HTML"
    echo "                </tr>" >> "$FICHIER_HTML"

    echo "Url $compteur traitée ($code_http)"
    compteur=$((compteur + 1))

done < "$FICHIER_URLS"

# Fin HTML
cat <<EOF >> "$FICHIER_HTML"
                        </tbody>
                    </table>
                </div>
                
                <div style="text-align:center; margin-top:2em;">
                    <a href="../tableaux.html" class="button" style="background-color: #1e3a8a; color: #ffffff !important; border: none;">Retour au choix des langues</a>
                </div>

            </section>
        </div>
        
        <div id="copyright">
            <ul><li>&copy; Projet PPE</li></ul>
        </div>
    </div>

    <script src="../assets/js/jquery.min.js"></script>
    <script src="../assets/js/jquery.scrollex.min.js"></script>
    <script src="../assets/js/jquery.scrolly.min.js"></script>
    <script src="../assets/js/browser.min.js"></script>
    <script src="../assets/js/breakpoints.min.js"></script>
    <script src="../assets/js/util.js"></script>
    <script src="../assets/js/main.js"></script>

</body>
</html>
EOF

rm -f page_temp.html page_temp_utf8.html
echo "Terminé ! Fichier généré avec Menu : $FICHIER_HTML"