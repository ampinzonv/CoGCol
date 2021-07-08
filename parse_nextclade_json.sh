#!/bin/bash
#
#   BIOINFORMATICS AND SYSTEMS BIOLOGY LABORATORY
#      UNIVERSIDAD NACIONAL DE COLOMBIA
#
# A simple script for parsing Nextclade`s json file.
#
# How to run it: 
# $> parse_nextclade_json.sh nextclade.json
#
# !!!Note that this script relies on "jq" for json file parsing.
#
#


jsonFile=${1}


#--------------------------------------------------------------------
# Get the number of entries (A.K.A genomes analyzed, fields in array).
# Nextclade json files has 4 initial objects. Last one (results) is an
# array. This array length is variable and it depends on the number og ¡genomes
# analyzed.
#--------------------------------------------------------------------
resultsLength=$(jq '.results[] | length' ${jsonFile} | wc -l)
#arrayLength=$(($l-1))

#--------------------------------------------------------------------
# Iterate through each object in array.
# Notice that 1st index in array is "0". So length = length-1
#--------------------------------------------------------------------
for (( i=0; i<$resultsLength; i++ ))
do
  
  #Get sample name
  sampleName=$(jq '.results['$i'].seqName' ${jsonFile})
  echo ${sampleName}
  
  #Get clade
  clade=$(jq '.results['$i'].clade' ${jsonFile})
  echo ${clade}

  #Get complete Aminoacid substitutions
  aaSubst=$(jq '.results['$i'].aaSubstitutions[] | .gene + ":" + .refAA + (.codon|tostring)+ .queryAA' ${jsonFile})
  echo ${aaSubst}

  #Get Nucleotide substitutions
  refNuc=$(jq '.results['$i'].substitutions[] | .refNuc + (.pos|tostring) + .queryNuc' ${jsonFile})
  echo ${refNuc} 

  echo "----------------"

done
