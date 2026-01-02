LANGUE=$1


cat ../contextes/${LANGUE}/*.txt > ../contextes/${LANGUE}/total_${LANGUE}.tmp
if [ -s "../contextes/${LANGUE}/total_${LANGUE}.tmp" ]; then
    wordcloud_cli --text "../contextes/${LANGUE}/total_${LANGUE}.tmp" \
		--imagefile "../images/wordcloud${LANGUE}.png" \
		--stopwords "../stopwords/stopwords-${LANGUE}.txt" \
		--mask "../images/bateau.png" \
		--scale 3 \
        --background white \
        --contour_width 3
else
	echo "Pas assez de texte pour générer un nuage de mots pour ${LANGUE}"
fi
