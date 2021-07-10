#!/bin/bash
#
#   BIOINFORMATICS AND SYSTEMS BIOLOGY LABORATORY
#      UNIVERSIDAD NACIONAL DE COLOMBIA
#
# A simple script for parsing Nextclade`s json file.
#
# How to run it: 
# $> create_ins_report nextclade.json  variantsOfConcern.lst path_to_mosdepth_genome_dir
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
  #  Please check that you provided 3 arguments and/or paths are correct.
  #
  #  This script requires the following input files:
  #
  #  1) A JSON file as obtained from NEXTCLADE.
  #  2) A one column file holding a list of Variants of Interest to look for.
  #  3) A path to a directory containing mosdepth coverage results. 

  #  Example:
  #
  #  parse_nextclade_json.sh  nextclade_output.json variants_file  mosdepth-genome-directory
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

if [ ! -d $3 ] || [ -z "$3"];then
  input_error "Mosdepth directory ${3} not found"
fi



#--------------------------------------------------------------------
# Input files
#--------------------------------------------------------------------
jsonFile=${1}
vocFile=${2}
mosDir=${3}

#Create a temp dir to hold tmp files
tmpDir=$(mktemp -d -p ./)

#--------------------------------------------------------------------
# Get the number of entries (A.K.A genomes analyzed, fields in array).
# Nextclade json files has 4 initial objects. Last one (results) is an
# array. This array length is variable and it depends on the number of 
# genomes analyzed.
#--------------------------------------------------------------------
resultsLength=$(jq '.results[] | length' ${jsonFile} | wc -l)


#--------------------------------------------------------------------
# Iterate through each object in array.
# Notice that 1st index in array is "0". So length = length-1
#--------------------------------------------------------------------
for (( i=0; i<$resultsLength; i++ ))
do
  
  # Get sample name
  # Sample name comes in the form: SAMPLE_01/ARTIC/medaka...
  # Let's use only the "SAMPLE_01" part for further consistency.
  # NOTE: This is true for the web version of the JSON file it is necessary to
  # check what de differences are with command line JSON file.
  sampleName=$(jq '.results['$i'].seqName' ${jsonFile} | sed -e 's/\"//g' | cut -d '/' -f 1)
  
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
  # MOSDEPTH ROUTINE
  # 
  #
  #------------------------------------------------------------------
  mosSummaryFile=$(echo ${mosDir}"/genome/"${sampleName}".mosdepth.summary.txt")
  meanDepth=$(tail ${mosSummaryFile} | awk '{print $4}')
  echo ${meanDepth} > ${tmpDir}/D



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
  # D: Mosdepth mean depth
  #
  #------------------------------------------------------------------
  cd ${tmpDir}

  #Replace line breaks from V file.
  cat v | tr '\n' ' '  > V

  #Paste does all the magic. Easy to modify columns position.
  paste S C V I N A D 
  
  #We need to get back one dir up.
  cd ..
  
  # Useful when terminal-debugging
  # echo "-----"

done


#Cleaning up.
rm -Rf ${tmpDir}

#Clean exit
exit 0
