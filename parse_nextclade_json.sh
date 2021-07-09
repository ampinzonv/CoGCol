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


#--------------------------------------------------------------------
#
# Minimal input check.
#
#--------------------------------------------------------------------
function input_error ()
{
  echo -e "
  #
  # ** ERROR **: ${1}
  # 
  #  Please check that you provided 2 arguments and/or paths are correct.
  #
  #  This script requires two input files:
  #
  #  1) A JSON file as obtained from NEXTCLADE.
  #  2) A one column file holding a list of Variants of Interest to look for.
  #
  #  Example:
  #
  #  parse_nextclade_json.sh nextclade_output.json variants_file
  #
  " 
  exit 0
}


if [ -z "$2" ]; then
  input_error "Missing argument"
fi
 
if [ ! -f $1 ];then
  input_error "File ${1} not found"
fi  
  
if [ ! -f $2 ];then
  input_error "File ${2} not found"
fi




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
  
  # File V is an special case. It needs to be reset before the loop. But
  # into the loop is not overwritten. Each loop is a new case.
  # Note that v and V are two different files that hold the same information
  # the difference is that v is the file before stripping end of lines.
  rm -f ${tmpDir}/v
  rm -f ${tmpDir}/V

  while read line
  do
   #Use -c to count number of matches. If == 1 means there was a match.
   match=$(echo ${aaSubst} | grep -c $line)
   
   if [ "$match" -eq 1 ];then
     
     # Here V file shouldn't be overwritten
     echo ${line}  >> ${tmpDir}/v  
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

  #Replace line breaks from V file.
  cat v | tr '\n' ' '  > V

  #Paste does all the magic. Easy to modify columns position.
  paste S C I A N V 
  
  #We need to get back one dir up.
  cd ..
  
  # USeful when terminal-debugging
  # echo "-----"

done

rm -Rf ${tmpDir}
