#!/bin/bash

#######################################
# One-off script for merging the 
# Dostoevsky repositories into a 
# single unified repository. This
# is part of the spring/summer 2026
# Computational Dostoevsky work.
#
# To run, you must call the main
# function explicitly:
#   bash -c ". ./merge.sh; main"
#
# You can also run individual targets
# for testing purposes.
#
# @author Joey Takeda
# @date April 14, 2026
#######################################


#######################################
# CONSTANTS                           
#######################################
GIT_URL=https://github.com/Digital-Dostoevsky
CURR_DIR=""
TMP_DIR="../tmp"
MERGED_DIR="../tei"

# Inelegant way of always making sure the directories are
# set up with proper full paths
if [ ! -d $TMP_DIR ]; then
  mkdir $TMP_DIR
fi

if [ ! -d $MERGED_DIR ]; then
  mkdir $MERGED_DIR
fi

# Now we can reassign the variable to make them full paths
TMP_DIR=$(realpath $TMP_DIR);
MERGED_DIR=$(realpath $MERGED_DIR);


#######################################
# FUNCTIONS
#######################################

#######################################
# clean_tmp: 
#   rimraf for the temporary directory
#######################################
clean_tmp () {
    [[ -d $TMP_DIR ]] && rm -rf $TMP_DIR
    mkdir $TMP_DIR
    TMP_DIR=$(realpath $TMP_DIR)
    echo $TMP_DIR
}

#######################################
# clean_merged: 
#    rimraf the merged directory
#######################################
clean_merged () {
    [[ -d $MERGED_DIR ]] && rm -rf $MERGED_DIR
    mkdir $MERGED_DIR
    MERGED_DIR=$(realpath $MERGED_DIR)
    echo $MERGED_DIR
}

#######################################
# checkout_repo:
#   Utility function to checkout a
#   given repo name. Note that this 
#   function both deletes the repo (if
#   it exists) and then sets the global
#   CURR_DIR to the repository's dir
#######################################
checkout_repo () {
    local REPO=$1
    CURR_DIR=$TMP_DIR/$REPO
    echo "## Processing ${REPO} into ${CURR_DIR}"
    # Delete repository if necessary 
    [[ -d $CURR_DIR ]] && rm -rf $CURR_DIR
    # Step 0: Go into temporary directory and clone
    echo cd $TMP_DIR 
    cd $TMP_DIR
    echo git clone $GIT_URL/$REPO
    git clone $GIT_URL/$REPO
    CURR_DIR=$(realpath $CURR_DIR)
    cd $CURR_DIR
}

#######################################
# process_texts:
#   Main function for processing all
#   text repositories and putting them
#   into the proper place. It does so
#   by iterating through the list of 
#   repositories ($REPOS)
#######################################
process_texts () {
    # First declare the repositories we want to work with
    declare -a REPOS=(
            "besy"
            "besy-temporality"
            "bratia_karamazovy"
            "dvoinik"
            "dvoinik-liminality"
            "idiot"
            "podrostok"
            "prestuplenie_i_nakazanie"
            "zapiski_iz_podpolia"
    )

    # Now loop through them all, checking them out
    # and then rewriting the history using git filter-repo
    for REPO in "${REPOS[@]}"; do
        checkout_repo $REPO
        cd $TMP_DIR/$REPO
        echo "#### STEP 1: CONSTRUCTING PATHS #####"
        # Step 1: Collect all of the paths we want to merge together,
        # starting with the README (which is more-or-less the same)
        # per file, but not entirely
        declare -a PATHS=(
            "README.md:texts/${REPO}/README.md"
        );
        # Iterate through each file and add to the PATHS array
        for file in *.xml; do
            # Most of the files have a transliterated name
            # in their TEI @xml:id, so we use that
            BASENAME=$(basename $file '.xml')
            TEI_ID=$(xmllint --xpath 'string(/*/@xml:id)' "${file}")
            # Catch this in case there is no @xml:id on the file
            ID=${TEI_ID:=$BASENAME}
            PATHS+=("${file}:texts/${REPO}/${ID}.xml")
        done
        echo "${PATHS[@]}"
        echo ""
        # Step 2: Now construct the git filter arguments
        echo "#### STEP 2: CONSTRUCTING ARGS #####"
        # Declare the empty array for now
        declare -a FILTER_ARGS=()
        # And now create the arguments by looping through the paths collected
        # in the PATHS array and tokenizing on the colon
        for pair in "${PATHS[@]}"; do
            src="${pair%%:*}" 
            dst="${pair##*:}"
            FILTER_ARGS+=(--path "$src")
            FILTER_ARGS+=(--path-rename "$src:$dst")
        done
        echo "${FILTER_ARGS[@]}"
        echo ""
        echo "#### STEP 3: FILTERING GIT REPO #####"
        # Step 3: Now run the command
        echo git filter-repo "${FILTER_ARGS[@]}"
        git filter-repo "${FILTER_ARGS[@]}" 
        echo ""
    done
}

#######################################
# process_corpus:
#   Process the corpus repo (i.e. the
#   plaintext files) into its own 
#   top-level directory.
#
#   TODO: It may be better to insert
#   the files where they belong (e.g. 
#   with each text). 
#######################################
process_corpus () {
    checkout_repo "corpus"
    git filter-repo \
        --path-glob '*.txt' \
        --path-rename '':'corpus/'
        # --path-rename 'Бесы - Proofed.txt':'corpus/besy.txt' \
        # --path-rename 'Бесы-У Тихона - Proofed.txt':'corpus/u_tikhona.txt' \
        # --path-rename 'Братья Карамазовы - Proofed.txt':'corpus/bratia_karamazovy.txt' \
        # --path-rename 'Двойник 1866 - Proofed.txt':'corpus/dvoinik-1866.txt' \
        # --path-rename 'Записки из подполья - Proofed.txt':'corpus/zapiski_iz_podpolia.txt' \
        # --path-rename 'Идиот - Proofed.txt':'corpus/idiot.txt' \
        # --path-rename 'Подросток.txt':'corpus/podrostok.txt' \
        # --path-rename 'Преступление и наказание - Proofed.txt':'corpus/prestuplenie_i_nakazanie.txt' 
}




#######################################
# process_schema:
#   Process the schema repository, 
#   splitting this into multiple places
#
#   TODO: Determine if we should keep
#   the archived stuff or if that can 
#   be left in the old (archived)
#   repository.
#######################################
process_schema () {
    checkout_repo "dostoevschema"
    # More complex; re-arrange a bunch of stuff
    git filter-repo \
        --path "dostoevschema.odd" \
        --path-rename 'dostoevschema.odd':"schema/dostoevschema.odd" \
        --path "dostoevschema.rng" \
        --path-rename 'dostoevschema.rng':"schema/dostoevschema.rng" \
        --path "build.xml" \
        --path-glob "utilities/*" \
        --path-rename 'build.xml':"utilities/schema/build.xml" \
        --path-rename "utilities/expand-ODD.xsl":"utilities/schema/expand-ODD.xsl" \
        --path-rename "utilities/fixes-2026.xsl":"utilities/fixes-2026.xsl" 
}

#######################################
# process_onomastica:
#   Move onomastica to the utilities/tagger 
#   directory (just the txt files)
#######################################
process_onomastica () {
    checkout_repo "digital-dostoevsky-onomastica"
    git filter-repo \
        --path-glob '*.txt' \
        --path-rename '':'utilities/tagger/onomastica/'
}

#######################################
# process_tagger:
#   Move the tagger into utilities
#   and rename
#######################################
process_tagger () {
    checkout_repo "digital-dostoevsky-tagger"
    git filter-repo \
        --path-glob '*' \
        --path-rename '':'utilities/tagger/'
}

#######################################
# process_networks:
#   Move the networks code into its
#   own directory within utilities
#######################################
process_networks () {
    checkout_repo "networks"

    git filter-repo \
        --path 'Extraction_code.xsl' \
        --path 'README.md' \
        --path-rename '':'utilities/networks/'
}

#######################################
# process_name_lists:
#   Move the generated name lists
#   into utilities. 
#######################################
process_name_lists () {
    checkout_repo "ner-generated-name-lists"
    git filter-repo \
        --path 'README.md' \
        --path-glob '*.txt' \
        --path-rename '':'utilities/ner-generated-name-lists/'
}

#######################################
# merge:
#   Loops through repositories in
#   the $TMP_DIR and merges their
#   respective histories into a single
#   repository. With thanks to 
#   https://stackoverflow.com/q/1425892
#######################################
merge () {
    cd $MERGED_DIR
    git init .
    for DIR_PATH in $TMP_DIR/*; do 
        DIR=$(basename $DIR_PATH)
        git remote add $DIR $DIR_PATH
        git fetch $DIR
        git merge \
            --allow-unrelated-histories \
            --no-edit \
            -m "Importing ${DIR}" \
            $DIR/main
        git remote remove $DIR
    done;
    echo "Merge completed. See tree output below"
    tree .
}

#######################################
# clean:
#   Calls the cleaning functions 
#######################################
clean () {
    clean_tmp
    clean_merged
}

#######################################
# process:
#   Calls all of the processing 
#   functions for the repositories
#######################################
process () {
    process_texts
    process_corpus
    process_schema
    process_onomastica
    process_tagger
    process_networks
    process_name_lists
}

#######################################
# main:
#   Main function that runs entire
#   process. 
#######################################
main () {
    clean
    process
    merge
}

