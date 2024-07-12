#!/bin/bash

set -x

#データベースのダウンロード
#なぜか北里大学の中ではファイルをftp://からダウンロードしようとすると必ずファイルサイズが違う変なファイルが出来てしまう
wget https://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz
wget https://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
tar vxf taxdump.tar.gz
cat names.dmp |awk -F'\t' '$7=="scientific name"{print $0}' > names.dmp.sname
awk -F'\t' '
 FILENAME==ARGV[1]{parent[$1]=$3}
 FILENAME==ARGV[2]{name[$1]=$3}
 END{for(i in name){str=name[i]; key=parent[i]; while(1){if(key==1){str=name[key]";"str; break}; str=name[key]";"str; key=parent[key]}; print i"\t"str}}
' nodes.dmp names.dmp.sname > names.dmp.sname.path

wget https://ftp.ncbi.nih.gov/blast/db/mito.tar.gz
tar vxf mito.tar.gz
blastdbcmd -db mito -entry all | gzip -c > mito.fasta.gz
#wget ftp://ftp.ncbi.nih.gov/refseq/release/plastid/plastid.*.genomic.fna.gz
for i in `curl https://ftp.ncbi.nih.gov/refseq/release/plastid/|grep plastid|grep genomic.fna.gz|sed 's/.*href="//; s/".*//'`; do
 wget https://ftp.ncbi.nih.gov/refseq/release/plastid/$i
done

(cat mito-all | grep "^>" | cut -f 2 -d '|'; zcat mito.fasta.gz plastid.*.genomic.fna.gz|grep "^>"|sed 's/^>//'|cut -f 1 -d '.')|awk -F'\t' 'FILENAME==ARGV[1]{a[$1]=1} FILENAME==ARGV[2]&&$1 in a{print $0}' /dev/stdin <(zcat nucl_gb.accession2taxid.gz) > nucl_gb.accession2taxid.mito-plastid.txt

seqkit fx2tab mito.fasta.gz plastid.*.genomic.fna.gz |awk -F'\t' 'FILENAME==ARGV[1]{path[$1]=$2} FILENAME==ARGV[2]{tax[$1]=$3} FILENAME==ARGV[3]{split($1,arr,"."); sp=path[tax[arr[1]]]; if(sp!=""){print ">"arr[1]" "sp"\n"$2}}' names.dmp.sname.path nucl_gb.accession2taxid.mito-plastid.txt /dev/stdin |sed 's/ root;cellular organisms;/ /' > ncbi-mito-plastid.fasta

wget -O complete_partial_mitogenomes.zip "http://mitofish.aori.u-tokyo.ac.jp/species/detail/download/?filename=download%2F/complete_partial_mitogenomes.zip"
unzip complete_partial_mitogenomes.zip
seqkit fx2tab mito-all |awk -F'\t' 'FILENAME==ARGV[1]{path[$1]=$2} FILENAME==ARGV[2]{tax[$1]=$3} FILENAME==ARGV[3]{split($1,arr,"|"); sp=path[tax[arr[2]]]; if(sp!=""){print ">MITOFISH_"arr[2]" "sp"\n"$2}}' names.dmp.sname.path nucl_gb.accession2taxid.mito-plastid.txt /dev/stdin |sed 's/ root;cellular organisms;/ /' > mito-fish.fasta

wget https://github.com/pr2database/pr2database/releases/download/v5.0.0/pr2_version_5.0.0_SSU_taxo_long.fasta.gz
seqkit fx2tab pr2_version_5.0.0_SSU_taxo_long.fasta.gz|awk -F'\t' '{split($1,arr,"|"); if(arr[2]=="18S_rRNA"){id="PR2_"arr[1]; desc=arr[5]; for(i=6;i<=length(arr);i++){desc=desc";"arr[i]}; print ">"id" "desc"\n"$2}}' > pr2_18S.fasta

wget https://www.arb-silva.de/fileadmin/silva_databases/current/Exports/SILVA_138.1_LSURef_NR99_tax_silva_trunc.fasta.gz
wget https://www.arb-silva.de/fileadmin/silva_databases/current/Exports/SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta.gz
seqkit fx2tab SILVA_138.1_LSURef_NR99_tax_silva_trunc.fasta.gz|awk -F'\t' '{split($1,arr," "); split(arr[2],arr2,";"); if(arr2[1]!="Eukaryota"){print ">SILVA-LSU_"$1"\n"$2}}' > silva-lsu.fasta
seqkit fx2tab SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta.gz|awk -F'\t' '{split($1,arr," "); split(arr[2],arr2,";"); if(arr2[1]!="Eukaryota"){print ">SILVA-SSU_"$1"\n"$2}}' > silva-ssu.fasta

cat *.fasta > mergedDB.fa

wget -O Sequencing_adaptors.fa https://raw.githubusercontent.com/suikoucalender/mitosearch_related_files/main/db/Sequencing_adaptors.fasta
makeblastdb -dbtype nucl -in mergedDB.fa
blastn -db mergedDB.fa -query Sequencing_adaptors.fa -outfmt 6 -max_target_seqs 10000000 -word_size 15|
 awk '{if($9<$10){print $2"\t"$9-1"\t"$10}else{print $2"\t"$10-1"\t"$9}}' > mergedDB.fa.adaptors.bed

# アダプター配列がヒットした場合のみ、アダプター配列のマスク
if [ `cat mergedDB.fa.adaptors.bed|wc -l` -gt 0 ]; then
    # FASTAの配列名のスペース以降はここで削れるのでスペース以降を再度付与する
    bedtools maskfasta -fi mergedDB.fa -bed mergedDB.fa.adaptors.bed -fo mergedDB.maskadaptors.temp.fa
    grep "^>" mergedDB.fa|sed 's/^>//; s/ /\t/'|awk -F'\t' 'FILENAME==ARGV[1]{path[$1]=$2} FILENAME==ARGV[2]{print ">"$1" "path[$1]"\n"$2}' /dev/stdin <(seqkit fx2tab mergedDB.maskadaptors.temp.fa) > mergedDB.maskadaptors.fa
    rm -f mergedDB.maskadaptors.temp.fa
else
    cat mergedDB.fa > mergedDB.maskadaptors.fa
fi

makeblastdb -dbtype nucl -max_file_sz 4GB -in mergedDB.maskadaptors.fa
cat mergedDB.maskadaptors.fa|grep "^>"|sed 's/^>//; s/ /\t/' > mergedDB.maskadaptors.fa.path

