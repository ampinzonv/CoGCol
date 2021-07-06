#!/bin/bash
#
#   BIOINFORMATICS AND SYSTEMS BIOLOGY LABORATORY
#      UNIVERSIDAD NACIONAL DE COLOMBIA
#
# DESCRIPTION:
# Gets and re-formats information from Nextclade CSV output files.
# This formatted information is used to generate the sequencing report
# for INS bioinformatics stuff.
#
#
# INPUT: 1)SAMPLE_file from nextclade 2)ins_variant file
#


#Let`s declare some constants
INS_VARIANTS_FILE=$2
ORFS=("ORF1a" "ORF1b" "S" "ORF3a" "E" "M" "ORF6" "ORF7a" "ORF7b" "ORF8" "ORF9b" "N")

#Create a unique name for each file
tfile=$(mktemp ./cogcol.XXXXXX)             #Temporary file
aaSubsFile=$(mktemp ./cogcol.XXXXXX)        #Holds aminoacid substitutions column (col17)
delFile=$(mktemp ./cogcol.XXXXXX)           #Holds deletion column data (col12)
insFile=$(mktemp ./cogcol.XXXXXX)           #Holds insertions column data (col13)
dnaSubsFile=$(mktemp ./cogcol.XXXXXX)       #Holds DNA substitutions column data (col11)
insVarList=$(mktemp ./cogcol_lst.XXXXXX)   #Holds a list of INS's VOC/VOI/VUO


#remove header line and save content
# For some reason "my" sed needs tab field separator, it shouldn't but...
cat ${1} | sed 1d | sed -e "s/;/\t/g"> ${tfile}


awk '{print $17}' ${tfile} > ${aaSubsFile} #Get the aa substitution data. send to file
for i in "${ORFS[@]}"                      #then in situ (-i) clean
do
  :
    sed -i "s/${i}://g" ${aaSubsFile}
done


cat ${INS_VARIANTS_FILE} | sed 1d | sed -e 's/;/\t/g' | awk '{print $2}' | sed -e 's/,/\n/g' > ${insVarList}


while read line
  do
    echo $line
  done < $insVarList


echo "----"
cat ${aaSubsFile}




