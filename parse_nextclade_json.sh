#!/bin/bash
#
#   BIOINFORMATICS AND SYSTEMS BIOLOGY LABORATORY
#      UNIVERSIDAD NACIONAL DE COLOMBIA
#
# A simple script for parsing Nextclade`s json file.
#
# How to run it: 
# $> parse_nextclade_json.sh nextclade.json  variantsOfConcern.lst
#
# !!!Note that this script relies on "jq" for json file parsing.
#
#


jsonFile=${1}
vocFile=${2}

#Create a temp dir to hold tmp files
tmpDir=$(mktemp -d -p ./)

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
  sampleName=$(jq '.results['$i'].seqName' ${jsonFile} | sed -e 's/\"//g')
  echo ${sampleName} > ${tmpDir}/S
  
  #Get clade
  clade=$(jq '.results['$i'].clade' ${jsonFile} | sed -e 's/\"//g')
  echo ${clade} > ${tmpDir}/C

  #Get complete Aminoacid substitutions
  aaSubst=$(jq '.results['$i'].aaSubstitutions[] | .gene + ":" + .refAA + (.codon|tostring)+ .queryAA' ${jsonFile} | sed -e 's/\"//g')
  echo ${aaSubst} > ${tmpDir}/A

  #Get Nucleotide substitutions
  refNuc=$(jq '.results['$i'].substitutions[] | .refNuc + (.pos|tostring) + .queryNuc' ${jsonFile} | sed -e 's/\"//g')
  echo ${refNuc}  > ${tmpDir}/N

  #Get insertions
  insertions=$(jq '.results['$i'].insertions[] | (.pos|tostring) + ":" + .ins' ${jsonFile} | sed -e 's/\"//g')
  #Sometimes there are no insertions at all
  if [ -z "${insertions}" ];then
    insertions=$(echo "NA")
  fi
  echo ${insertions} > ${tmpDir}/I

  #------------------------------------------------------------------
  # Let's see if any of the retrieved aminoacid substitutions is one
  # of the VOI/VOC according to the data provided by the INS.
  # For this we need a list of VOI/VOC. This list was created as a
  # single column file and provided to this script as a parameter 2.
  #------------------------------------------------------------------
  
  # In some systems GREP_OPTIONS is set although it is deprecated
  # no harm in this unset. Warnings are annoying!
  unset GREP_OPTIONS
  
  while read line
  do
   #Use -c to count number of matches. If == 1 means there was a match.
   match=$(echo ${aaSubst} | grep -c $line)
   
   if [ "$match" -eq 1 ];then
     echo ${line}  > ${tmpDir}/V  
   fi
 done < ${vocFile}

  set GREP_OPTIONS

  #------------------------------------------------------------------
  # We need to gather all retrieved information and format it in a 
  # single row  then save to a file.
  #
  # S: Sample name
  # C: Clade
  # I: Insertions
  # A: Aminoacid Substitutions
  # N: Nucleotide substitutions
  # V: Variants of interest
  #
  #------------------------------------------------------------------
  cd ${tmpDir}
  
  #Paste does all the magic.
  paste S C I A N 

  #We need to get back one dir up.
  cd ..

  echo "-----"

done

rm -Rf ${tmpDir}
