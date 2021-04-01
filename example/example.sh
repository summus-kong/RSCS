#!/bin/bash

# Test RSCS

chmod u+x ../bin/RSCS.sh
mkdir output

# run
bash ../bin/RSCS.sh -r ./rnaseq -s ./srnaseq \
-e path/genome.fa -o ./output \
--single_or_pairedr TRUE --single_or_paireds TRUE \
-m meta -p 8
