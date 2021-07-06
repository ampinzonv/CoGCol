ins_variants.tsv
El archivo: ins_variants.tsv fue creado a partir de la información proveída
por el INS a través de un email. Es un PDF con las especificaciones para
realizar el reporte a GISAID. Manualmente para cada variante se creó el archivo.

ins_variants_long.lst
Es un archivo obtenido a partir del archvo ins_variants.tsv mediante el comando:

sed -e 's/;/\t/g' ins_variants.tsv | awk '{print $2}' | sed -e 's/,/\n/g' > ins_variants_long.lst

Este contiene la lista de todas las variantes independientemente de su relación
con loslinajes. Es útil para parsear qué variantes de interés hay en cada
asignación realizada por NEXTCLADE.
