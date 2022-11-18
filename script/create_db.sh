#!/bin/bash

# SSUなどのデータベースを更新する際、このスクリプトにかける。[cat SSU~.fa pr2~.fa mitofish.fa > ../db/mergedDB.fasta]とした後、このスクリプトでアダプター除去等を行う。
# 使用法：bash create_db.sh [../db/mergedDB.fasta]

set -ex
unset LC_ALL

# フォルダ等の設定を読み込み
sdir=$(dirname `readlink -f "$0" || echo "$0"`)
source "$sdir"/config.sh

#Singularityのイメージがなければ、githubのリリースから取ってくる。ファイルサイズが大きいのでソースコードには含められない。
#singularity build seqkit.sif docker://quay.io/biocontainers/seqkit:2.3.1--h9ee0642_0
if [ ! -e "${workdir}/singularity_image/seqkit.sif" ]; then
 wget -O "${workdir}/singularity_image/seqkit.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/seqkit.sif
fi

#singularity build bedtools.sif docker://quay.io/biocontainers/bedtools:2.30.0--hc088bd4_0
if [ ! -e "${workdir}/singularity_image/bedtools.sif" ]; then
 wget -O "${workdir}/singularity_image/bedtools.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/bedtools.sif
fi

#singularity build blast.sif docker://quay.io/biocontainers/blast:2.13.0--hf3cf87c_0
if [ ! -e "${workdir}/singularity_image/blast.sif" ]; then
 wget -O "${workdir}/singularity_image/blast.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/blast.sif
fi

#データベースのダウンロード
for i in 16S_ribosomal_RNA LSU_prokaryote_rRNA mito; do
 wget ftp://ftp.ncbi.nih.gov/blast/db/$i.tar.gz
 tar vxf $i.tar.gz
 ${singularity_path} run ${workdir}/singularity_image/blast.sif blastdbcmd -db $i -entry all > $i.fasta
done
wget ftp://ftp.ncbi.nih.gov/refseq/release/plastid/plastid.*.genomic.fna.gz
if [ ! -e pr2_version_4.14.0_SSU_taxo_long.fasta.gz ]; then
 wget https://github.com/pr2database/pr2database/releases/download/v4.14.0/pr2_version_4.14.0_SSU_taxo_long.fasta.gz
fi
for i in plastid.*.genomic.fna.gz pr2_version_4.14.0_SSU_taxo_long.fasta.gz; do
 gzip -d $i
done
wget -O complete_partial_mitogenomes.zip http://mitofish.aori.u-tokyo.ac.jp/species/detail/download/?filename=download%2F/complete_partial_mitogenomes.zip
unzip complete_partial_mitogenomes.zip
cat *.fasta *.fna mito-all > mergedDB.fa

db=mergedDB.fa

wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz
wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
tar vxf taxdump.tar.gz
cat names.dmp |awk -F'\t' '$7=="scientific name"{print $0}' > names.dmp.sname
awk -F'\t' '
 FILENAME==ARGV[1]{parent[$1]=$3}
 FILENAME==ARGV[2]{name[$1]=$3}
 END{for(i in name){str=name[i]; key=parent[i]; while(1){if(key==1){str=name[key]";"str; break}; str=name[key]";"str; key=parent[key]}; print i"\t"str}}
' nodes.dmp names.dmp.sname > names.dmp.sname.path


# makeblastdb,アダプター配列の検索
if [ ! -e "$sdir"/Sequencing_adaptors.fasta ]; then cp "$sdir"/Sequencing_adaptors.fasta .; fi
${singularity_path} run ${workdir}/singularity_image/blast.sif makeblastdb -dbtype nucl -in $db
${singularity_path} run ${workdir}/singularity_image/blast.sif blastn -db $db -query Sequencing_adaptors.fasta -outfmt 6 -max_target_seqs 10000000 -word_size 15|
 awk '{if($9<$10){print $2"\t"$9-1"\t"$10}else{print $2"\t"$10-1"\t"$9}}' > ${db}.adaptors.bed

# アダプター配列のマスク
${singularity_path} run ${workdir}/singularity_image/bedtools.sif bedtools maskfasta -fi $db -bed ${db}.adaptors.bed -fo ${db}.maskadaptors

# データベースに載っているアクセッションIDのリストを作成
${singularity_path} run ${workdir}/singularity_image/seqkit.sif seqkit fx2tab ${db}.maskadaptors|awk -F"\t" '{split($1,array,".");print array[1];}'|
 awk -F"\t" '{if(substr($1,1,2)=="gb"){split($1,array,"|");print array[2];}else{print;}}' > ${db}.maskadaptors.accessionID

# 上のリストに対応するacc2taxidデータベースの抽出
awk -F"\t" '{if(FILENAME==ARGV[1]){list[$1]=1;}if(FILENAME==ARGV[2]&&$1 in list){print;}}' ${db}.maskadaptors.accessionID <(zcat nucl_gb.accession2taxid.gz) > ${db}.maskadaptors.nucl_gb.accession2taxid

# 2つ上で抽出したaccession2taxidリストに対応するnames.dumpを抽出
awk -F"\t" '{if(FILENAME==ARGV[1]){list[$3]=1;}if(FILENAME==ARGV[2]&&$1 in list){print;}}' ${db}.maskadaptors.nucl_gb.accession2taxid names.dmp.sname.path > ${db}.maskadaptors.names.dmp

# NCBIから消去されたアクセッションIDリストを取得
awk -F"\t" '{if(FILENAME==ARGV[1]){list[$1]=1;}if(FILENAME==ARGV[2]){delete list[$1];}}END{for(i in list){print i;}}' ${db}.maskadaptors.accessionID ${db}.maskadaptors.nucl_gb.accession2taxid > removed_accessionID.txt

# データベースをタブ区切りにして保存
${singularity_path} run ${workdir}/singularity_image/seqkit.sif seqkit fx2tab ${db}.maskadaptors > ${db}.maskadaptors.tab

# 消去されたアクセッションIDに対応するデータを除去したデータベースの作成
awk -F"\t" '{if(FILENAME==ARGV[1]){list[$1]=1;}if(FILENAME==ARGV[2]){split($1,array,".");if(substr(array[1],1,2)=="gb"){split(array[1],array2,"|");acc=array2[2];}else{acc=array[1];}if(acc in list){}else{print;}}}' removed_accessionID.txt ${db}.maskadaptors.tab|
 ${singularity_path} run ${workdir}/singularity_image/seqkit.sif seqkit tab2fx > database.fasta

# makeblastdb
${singularity_path} run ${workdir}/singularity_image/blast.sif makeblastdb -dbtype nucl -max_file_sz 50MB -in database.fasta
