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
# EXAMPLE: $> thiscript SAMPLE01.nextclade  insvarfile.csv 



INS_VARIANTS_FILE=$2

#These are Sars-Cov2 known ORFs
ORFS=("ORF1a" "ORF1b" "S" "ORF3a" "E" "M" "ORF6" "ORF7a" "ORF7b" "ORF8" "ORF9b" "N")


#Create a unique name for each file
tfile=$(mktemp ./cc-tfile.XXXXXX)             #Temporary file
aaSubsFile=$(mktemp ./cc-aaSubs.XXXXXX)        #Holds aminoacid substitutions column (col17)
delFile=$(mktemp ./cc-del.XXXXXX)           #Holds deletion column data (col12)
insFile=$(mktemp ./cc-insert.XXXXXX)           #Holds insertions column data (col13)
dnaSubsFile=$(mktemp ./cc-dnaSubs.XXXXXX)       #Holds DNA substitutions column data (col11)
insVarList=$(mktemp ./cc-lst.XXXXXX)   #Holds a list of INS's VOC/VOI/VUO


#--------------------------------------------------------------------
# Parse NEXTCLADE csv file
# remove header line and get columns 1,2,12,13,11 and 17
# For some reason "my" sed needs tab field separator, it shouldn't but...
#--------------------------------------------------------------------
cat ${1} | sed 1d | sed -e "s/;/\t/g" | sed -e "s/\"//g" | awk -F"\t" '{print $1,$2,$12,$13,$11,$17}' > ${tfile}

#--------------------------------------------------------------------
#In order to get the "Mutacion de interes" column, as required by the INS it is
#necessary to get the column 17 from Nextclade file and compare it to the list
#of VOI as provided by the INS in their PDF file with recommendations.
#--------------------------------------------------------------------
cat ${tfile} | awk '{print $6}' #Get the aa substitution data (Col 17).

exit 0

for i in "${ORFS[@]}"                      #then in situ (-i) clean
do
  :
    sed -i "s/${i}://g" ${aaSubsFile}
done

cat ${aaSubsFile}
echo "----"
echo "----"


#--------------------------------------------------------------------
# Parse ins_var file that comes in the form:
# Linaje;Variantes
# B.1.1.7;N501Y
# B.1.1.7;P681H
# Output as a long list
#--------------------------------------------------------------------
cat ${INS_VARIANTS_FILE} | sed 1d | sed -e 's/;/\t/g' | awk '{print $2}' | sed -e 's/,/\n/g' > ${insVarList}


while read line
  do
    echo $line
  done < $insVarList





