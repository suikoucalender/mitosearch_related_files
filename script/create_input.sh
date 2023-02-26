#!/bin/bash

set -ex

# SRA番号
prefix=$1

# フォルダ等の設定を読み込み
sdir=$(dirname `readlink -f "$0" || echo "$0"`)
source "$sdir"/config.sh

#Singularityのイメージがなければ、githubのリリースから取ってくる。ファイルサイズが大きいのでソースコードには含められない。
if [ ! -e "${workdir}/singularity_image/flash.sif" ]; then
 wget -O "${workdir}/singularity_image/flash.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/flash.sif
fi

if [ ! -e "${workdir}/singularity_image/cutadapt.sif" ]; then
 wget -O "${workdir}/singularity_image/cutadapt.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/cutadapt.sif
fi

if [ ! -e "${workdir}/singularity_image/python_xlrd.sif" ]; then
 wget -O "${workdir}/singularity_image/python_xlrd.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/python_xlrd.sif
fi

#singularity build seqkit.sif docker://quay.io/biocontainers/seqkit:2.3.1--h9ee0642_0
if [ ! -e "${workdir}/singularity_image/seqkit.sif" ]; then
 wget -O "${workdir}/singularity_image/seqkit.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/seqkit.sif
fi


# 一時ファイルを配置するディレクトリをサンプルごとに作成
mkdir -p ${tmpdir}/${prefix}

edna_sequence_filedir="$edna_file"
logfile=${tmpdir}/${prefix}/log.txt
rm -f "$logfile"

# Pair EndのシーケンスデータはFLASHでマージしたのちに、マージがされなかったForward側のリードを結合する
if [ -e ${edna_sequence_filedir}/${prefix}_1.fastq.gz -a -e ${edna_sequence_filedir}/${prefix}_2.fastq.gz ]; then
    cp -f ${edna_sequence_filedir}/${prefix}_1.fastq.gz ${edna_sequence_filedir}/${prefix}_2.fastq.gz ${tmpdir}/${prefix}
    zcat ${tmpdir}/${prefix}/${prefix}_1.fastq.gz| awk 'END{print "input read 1: "NR/4}' >> "$logfile"
    zcat ${tmpdir}/${prefix}/${prefix}_2.fastq.gz| awk 'END{print "input read 2: "NR/4}' >> "$logfile"
    #gunzip ${tmpdir}/${prefix}/${prefix}_1.fastq.gz
    # FLAShによるペアエンドリードのマージを行った後に、マージに失敗したリードについてはForward側のみをFLAShの出力ファイル(out.extendedFrags.fastq)に追加する。
    # マージに失敗(ペアエンド間でリード数が異なる場合など)ではForward側のリードファイルを使用する(out.extendedFrags.fastqというファイルにForward側のリード配列を格納)
    # echo "singularity run --bind ${edna_sequence_filedir}:${edna_sequence_filedir} ${workdir}/singularity_image/flash.sif -d ${tmpdir}/${prefix} -M 300 ${edna_sequence_filedir}/${prefix}_1.fastq.gz ${edna_sequence_filedir}/${prefix}_2.fastq.gz"
    ( ( ${singularity_path} run ${workdir}/singularity_image/flash.sif flash -d ${tmpdir}/${prefix} -M 300 ${tmpdir}/${prefix}/${prefix}_1.fastq.gz ${tmpdir}/${prefix}/${prefix}_2.fastq.gz ) &&
        awk 'END{print "jointed reads: "NR/2}' ${tmpdir}/${prefix}/out.extendedFrags.fastq >> "$logfile" &&
        cat ${tmpdir}/${prefix}/out.notCombined_1.fastq >> ${tmpdir}/${prefix}/out.extendedFrags.fastq
      ) || zcat ${tmpdir}/${prefix}/${prefix}_1.fastq.gz > ${tmpdir}/${prefix}/out.extendedFrags.fastq
    awk 'END{print "not combined 1: "NR/4}' ${tmpdir}/${prefix}/out.notCombined_1.fastq >> "$logfile"
    awk 'END{print "not combined 2: "NR/4}' ${tmpdir}/${prefix}/out.notCombined_2.fastq >> "$logfile"

#elif [ -e ${edna_sequence_filedir}/${prefix}_1.fastq -a -e ${edna_sequence_filedir}/${prefix}_2.fastq ]; then
#    cp -f ${edna_sequence_filedir}/${prefix}_1.fastq ${edna_sequence_filedir}/${prefix}_2.fastq ${tmpdir}/${prefix}
#    cat ${tmpdir}/${prefix}/${prefix}_1.fastq| awk 'END{print "input read 1: "NR/4}' >> "$logfile"
#    cat ${tmpdir}/${prefix}/${prefix}_2.fastq| awk 'END{print "input read 2: "NR/4}' >> "$logfile"
#    ( ( ${singularity_path} run ${workdir}/singularity_image/flash.sif flash -d ${tmpdir}/${prefix} -M 300 ${tmpdir}/${prefix}/${prefix}_1.fastq ${tmpdir}/${prefix}/${prefix}_2.fastq ) &&
#        awk 'END{print "jointed reads: "NR/2}' ${tmpdir}/${prefix}/out.extendedFrags.fastq >> "$logfile" &&
#        cat ${tmpdir}/${prefix}/out.notCombined_1.fastq >> ${tmpdir}/${prefix}/out.extendedFrags.fastq
#      ) || cat ${tmpdir}/${prefix}/${prefix}_1.fastq > ${tmpdir}/${prefix}/out.extendedFrags.fastq

# Single Endのシーケンスデータはそのリードをそのまま使用する
else
    if [ -e ${edna_sequence_filedir}/${prefix}_1.fastq.gz ]; then
        cp ${edna_sequence_filedir}/${prefix}_1.fastq.gz ${tmpdir}/${prefix}
        zcat ${tmpdir}/${prefix}/${prefix}_1.fastq.gz > ${tmpdir}/${prefix}/out.extendedFrags.fastq
        awk 'END{print "single reads: "NR/4}' ${tmpdir}/${prefix}/out.extendedFrags.fastq >> "$logfile"
    fi

    if [ -e ${edna_sequence_filedir}/${prefix}_2.fastq.gz ]; then
        cp ${edna_sequence_filedir}/${prefix}_2.fastq.gz ${tmpdir}/${prefix}
        zcat ${tmpdir}/${prefix}/${prefix}_2.fastq.gz > ${tmpdir}/${prefix}/out.extendedFrags.fastq
        awk 'END{print "single reads: "NR/4}' ${tmpdir}/${prefix}/out.extendedFrags.fastq >> "$logfile"
    fi
fi

# Illuminaアダプター配列一覧を取得し、一致領域以降の配列を除去。デフォルトでは3塩基のみの一致でも配列除去してしまうので、10塩基以上一致に変更(--overlap 10)。
adapter=`${singularity_path} run -B "$workdir" ${workdir}/singularity_image/seqkit.sif seqkit fx2tab $workdir/db/Sequencing_adaptors.fasta |awk -F" " '{print " -a "$2;}'|tr -d '\n'|sed s/" "//`
${singularity_path} run -B "$workdir" ${workdir}/singularity_image/cutadapt.sif cutadapt --overlap 10 ${adapter} -j 8 -o ${tmpdir}/${prefix}/out.extendedFrags_trimed.fastq ${tmpdir}/${prefix}/out.extendedFrags.fastq
awk 'END{print "after cutadapt: "NR/4}' ${tmpdir}/${prefix}/out.extendedFrags_trimed.fastq >> "$logfile"

# FASTQからFATSTAファイルに変換。N以外に30bp以上の塩基がなければ削除。シャッフルして100万リードまで使用する。
cat "${tmpdir}/${prefix}/out.extendedFrags_trimed.fastq"|paste - - - - |shuf|awk -F'\t' '{n=split($2,arr,"N"); if(n<=length($2)-29){print ">"substr($1,2); print $2}}'|
 awk 'NR<=2*1000*1000{print $0}' > ${tmpdir}/${prefix}/out.extendedFrags_trimed.fasta
awk 'END{print "after remove N reads: "NR/2}' ${tmpdir}/${prefix}/out.extendedFrags_trimed.fasta >> "$logfile"

#【cutadapt検証用】cutadaptされたリードの元の配列と処理後の配列を比較する。解析フローには不要。
# awk '(NR - 1) % 4 < 2' ${tmpdir}/${prefix}/out.extendedFrags.fastq | sed 's/@/>/' > ${tmpdir}/${prefix}/out.extendedFrags.fasta
# awk -F"\t" '{if(FILENAME==ARGV[1]){list[$1]=$2;}if(FILENAME==ARGV[2]&&list[$1]!=$2){a=list[$1];sub($2,"",a);print list[$1]"\t"$2"\t"a;}}' <(seqkit fx2tab ${tmpdir}/${prefix}/out.extendedFrags.fasta <(seqkit fx2tab ${tmpdir}/${prefix}/out.extendedFrags_trimed.fasta) > ../inputFiles/${prefix}.adapters

# データベースに対してBlastnで相同性検索を行う。
${blastn_path} -num_threads 8 -db ${blastdb} -query ${tmpdir}/${prefix}/out.extendedFrags_trimed.fasta -outfmt "6 qseqid sseqid qlen slen pident length mismatch gapopen qstart qend sstart send evalue bitscore staxids stitle" -max_target_seqs 10 | awk -F'\t' 'a[$1]!=1{a[$1]=1; print $0}' > ${tmpdir}/${prefix}/blast.result
awk 'END{print "blast hits: "NR}' ${tmpdir}/${prefix}/blast.result >> "$logfile"

# ハイスコアなblast結果のトップヒットを抽出し、アクセッションIDのリストに変換
# リード長が100bpより大きく、一致率が90%より上、アライメントの長さがリードの90%もしくはDBの90%より大きいヒットを抽出
cat ${tmpdir}/${prefix}/blast.result | awk '$3 > 100 && $5 > 90 && ($6/$3 > 0.9 || $6/$4 > 0.9)' | cut -f 1,2 | sort | uniq | cut -f 2 |
 awk -F"\t" '{if(substr($1,1,1)=="g"){split($1,array,"|");{print array[2];}}else{split($1,array,".");{print array[1];}}}' > ${tmpdir}/${prefix}/blast.result2
awk 'END{print "after blast hits filtering: "NR}' ${tmpdir}/${prefix}/blast.result2 >> "$logfile"

# アクセッションIDをtaxonomyに変換、ヒット数集計。魚類のみを抽出し、全体リードの1%未満のヒットは消去。taxonomyを学名に変換（交雑種は母方の学名のみ抽出）し、inputファイルの完成。
awk -F"\t" '
 BEGIN{list["accession"]="exist";list2["accession"]="taxid";list3["taxid"]="exist";list4["taxid"]="taxname";}
 {
  if(FILENAME==ARGV[1]){list[$1]=1;}
  if(FILENAME==ARGV[2] && $1 in list){list2[$1]=$3;delete list[$1];list3[$3]=1;}
  if(FILENAME==ARGV[3] && $1 in list3){list4[$1]=$2;delete list3[$1];}
  if(FILENAME==ARGV[4]){$1=list4[list2[$1]];print $0;}
 }' ${tmpdir}/${prefix}/blast.result2 $workdir/db/merged.fasta.maskadaptors.nucl_gb.accession2taxid $workdir/db/merged.fasta.maskadaptors.names.dmp ${tmpdir}/${prefix}//blast.result2 |
 awk -F"\t" '
  BEGIN{list["tax"]="num";}{if($1 in list){list[$1]=list[$1]+1;}else{list[$1]=1;}}
  END{delete list["tax"];PROCINFO["sorted_in"]="@val_num_desc";for(i in list){print list[i]"\t"i;}}
 ' | grep ";Craniata;" | grep -v ";Tetrapoda;" |
 awk -F"\t" '{split($2,arr,";");if(arr[length(arr)]~" x "){split(arr[length(arr)],array," x ");print $1"\t"array[length(array)];}else{print $1"\t"arr[length(arr)];}}' |
 awk -F"\t" '
  BEGIN{list["tax"]="num";}
  {if($2 in list){list[$2]+=$1;}else{list[$2]=$1;}}
  END{delete list["tax"];PROCINFO["sorted_in"]="@val_num_desc";for(i in list){print list[i]"\t"i;}}
 ' |
 awk -F"\t" '
  BEGIN{sum=0;}
  {sum=sum+$1;list[$2]=$1;}
  END{sum=sum/100;PROCINFO["sorted_in"]="@val_num_desc";for(i in list){if(list[i]>sum){print list[i]"\t"i;}}}
 ' > ${tmpdir}/${prefix}/${prefix}.input.temp
awk -F'\t' '{a+=$1} END{print "after removing under 1% hits: "a}' ${tmpdir}/${prefix}/${prefix}.input.temp >> "$logfile"

cat "$logfile"

#出力が0でなければ続行
if [ -s ${tmpdir}/${prefix}/${prefix}.input.temp ]; then

#ヒットが100リード以上なら続行
if [ `awk -F'\t' '{a+=$1} END{print a}' ${tmpdir}/${prefix}/${prefix}.input.temp` -gt 99 ]; then

#合計を100%にする
cat ${tmpdir}/${prefix}/${prefix}.input.temp|
 awk -F'\t' '{if(FNR==1){print "id\t'${prefix}'.fastq"}; n[NR]=$2; v[NR]=$1; cnt+=$1} END{for(i=1;i<=NR;i++){print n[i]"\t"v[i]/cnt*100}}' > "${tmpdir}/${prefix}/${prefix}.input"

# 和名変換。まず、データベース内で学名が完全に一致する種を探す。これでヒットしなかった場合、属名が同じ種の科名を返す。
awk -F'\t' '
 FILENAME==ARGV[1]{data[$2]=$1; split($2,arr, " "); data2[arr[1]]=$3}
 FILENAME==ARGV[2]{
  if(FNR==1){print $0}
  else{str=""; for(i in data){if(i~$1){str=data[i]; break}}; OFS="\t";
   if(str!=""){$1=str":"$1}else{split($1,arr," "); if(arr[1] in data2){$1=data2[arr[1]]":"$1}};
   print $0;
  }
 }
' "$workdir/db/scientificname2japanesename_complete.csv" "${tmpdir}/${prefix}/${prefix}.input" > "${tmpdir}/${prefix}/${prefix}.input2"

#awk -F"\t" '
# {if(FILENAME==ARGV[1]){list[$2]=$1;}if(FILENAME==ARGV[2]){for(i in list){if($2~i){list2[$1":"i]=list[i];delete list[i];}}}}
# END{PROCINFO["sorted_in"]="@val_num_desc";for(i in list2){print list2[i]"\t"i;}}
#' ${tmpdir}/${prefix}/${prefix}.input $workdir/db/scientificname2japanesename_complete.csv > ${tmpdir}/${prefix}/${prefix}.input2

#awk -F"\t" '
# {if(FILENAME==ARGV[1]){list[$2]=$1;}if(FILENAME==ARGV[2]){for(i in list){if($2~i){delete list[i];}}}}
# END{for(i in list){print list[i]"\t"i;}}
#' ${tmpdir}/${prefix}/${prefix}.input ${tmpdir}/${prefix}/${prefix}.input2 > ${tmpdir}/${prefix}/${prefix}.input3
#awk -F"\t" '
# {if(FILENAME==ARGV[1]){list[$2]=$1;}if(FILENAME==ARGV[2]){for(i in list){split(i,array," ");if($2~array[1]){list[$3":"i]=list[i];delete list[i];}}}}
# END{PROCINFO["sorted_in"]="@val_num_desc";for(i in list){print list[i]"\t"i;}}
#' ${tmpdir}/${prefix}/${prefix}.input3 $workdir/db/scientificname2japanesename_complete.csv > ${tmpdir}/${prefix}/${prefix}.input4
#cat ${tmpdir}/${prefix}/${prefix}.input2 ${tmpdir}/${prefix}/${prefix}.input4|
# awk -F"\t" '{list[$2]=$1;}END{PROCINFO["sorted_in"]="@val_num_desc";for(i in list){print list[i]"\t"i;}}' > ${tmpdir}/${prefix}/${prefix}.input5

mv "${tmpdir}/${prefix}/${prefix}.input2" "${outputFileDirPath}/${prefix}.input"

fi
fi

#if [ ! -s ${outputFileDirPath}/${prefix}.input ]; then rm -f ${outputFileDirPath}/${prefix}.input; fi

#一時ディレクトリ内の中間ファイルを消去
rm -rf ${tmpdir}/${prefix}
