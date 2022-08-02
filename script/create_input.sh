#!/bin/bash

set -x

# SRA番号
prefix=$1

# ------------

# Workdir
workdir=/home/yoshitake/mitosearch_related_files
# Scriptが配置されているディレクトリ
scriptdir=${workdir}/script
# 各サンプルの一時ファイルを配置するディレクトリを格納するディレクトリ
tmpdir=${workdir}/tmp
# サンプルデータを配置するディレクトリ(各ディレクトリでファイルの重複がないようにする必要がある)
edna_file_list=(${workdir}/fastq)
# MitoFishのBlast DBファイル
blastdb=${workdir}/db/complete_partial_mitogenomes.fa
# inputファイルの出力先ディレクトリ
outputFileDirPath=${workdir}/inputFiles
# 魚種和名ファイルのPath
fishname_ja_Path=${workdir}/db/20210718_JAFList.xlsx
# singularityのPath
singularity_path=/home/yoshitake/tool/singularity-3.5.2/bin/singularity
# blastnのPATH
blastn_path=/home/yoshitake/ncbi-blast-2.13.0+/bin/blastn

# ------------

# 一時ファイルを配置するディレクトリをサンプルごとに作成
mkdir -p ${tmpdir}/${prefix}

for edna_sequence_filedir in ${edna_file_list[@]}
do

# Pair EndのシーケンスデータはFLASHでマージしたのちに、マージがされなかったForward側のリードを結合する
if [ -e ${edna_sequence_filedir}/${prefix}_1.fastq.gz -a -e ${edna_sequence_filedir}/${prefix}_2.fastq.gz ]; then
    cp ${edna_sequence_filedir}/${prefix}_1.fastq.gz ${tmpdir}/${prefix}
    gunzip ${tmpdir}/${prefix}/${prefix}_1.fastq.gz
    # FLAShによるペアエンドリードのマージを行った後に、マージに失敗したリードについてはForward側のみをFLAShの出力ファイル(out.extendedFrags.fastq)に追加する。
    # マージに失敗(ペアエンド間でリード数が異なる場合など)ではForward側のリードファイルを使用する(out.extendedFrags.fastqというファイルにForward側のリード配列を格納)
    # echo "singularity run --bind ${edna_sequence_filedir}:${edna_sequence_filedir} ${workdir}/singularity_image/flash.sif -d ${tmpdir}/${prefix} -M 300 ${edna_sequence_filedir}/${prefix}_1.fastq.gz ${edna_sequence_filedir}/${prefix}_2.fastq.gz"
    { { ${singularity_path} run --bind ${edna_sequence_filedir}:${edna_sequence_filedir} ${workdir}/singularity_image/flash.sif -d ${tmpdir}/${prefix} -M 300 ${edna_sequence_filedir}/${prefix}_1.fastq.gz ${edna_sequence_filedir}/${prefix}_2.fastq.gz; } && cat ${tmpdir}/${prefix}/out.notCombined_1.fastq >> ${tmpdir}/${prefix}/out.extendedFrags.fastq; } || cat ${tmpdir}/${prefix}/${prefix}_1.fastq > ${tmpdir}/${prefix}/out.extendedFrags.fastq
    
# Single Endのシーケンスデータはそのリードをそのまま使用する
else
    if [ -e ${edna_sequence_filedir}/${prefix}_1.fastq.gz ]; then
        cp ${edna_sequence_filedir}/${prefix}_1.fastq.gz ${tmpdir}/${prefix}
        gunzip ${tmpdir}/${prefix}/${prefix}_1.fastq.gz
        mv ${tmpdir}/${prefix}/${prefix}_1.fastq ${tmpdir}/${prefix}/out.extendedFrags.fastq

    fi

    if [ -e ${edna_sequence_filedir}/${prefix}_2.fastq.gz ]; then
        cp ${edna_sequence_filedir}/${prefix}_2.fastq.gz ${tmpdir}/${prefix}
        gunzip ${tmpdir}/${prefix}/${prefix}_2.fastq.gz
        mv ${tmpdir}/${prefix}/${prefix}_2.fastq ${tmpdir}/${prefix}/out.extendedFrags.fastq

    fi

fi

done

# MiFishプライマーのリバース側の相補鎖以降の配列(Adapter Primerも含む)を除去
${singularity_path} run ${workdir}/singularity_image/cutadapt.sif cutadapt -a CAAACTAGGATTAGATACCCCACTATG -o ${tmpdir}/${prefix}/out.extendedFrags_trimed.fastq ${tmpdir}/${prefix}/out.extendedFrags.fastq

# FASTQからFATSTAファイルに変換
awk '(NR - 1) % 4 < 2' ${tmpdir}/${prefix}/out.extendedFrags_trimed.fastq | sed 's/@/>/' > ${tmpdir}/${prefix}/out.extendedFrags_trimed.fasta

# MitoFishデータベースに対してBlastnで相同性検索を行う。
#${blastn_path} -num_threads 8 -db ${blastdb} -query ${tmpdir}/${prefix}/out.extendedFrags_trimed.fasta -outfmt "6 qseqid sseqid qlen slen pident length mismatch gapopen qstart qend sstart send evalue bitscore staxids stitle" -max_target_seqs 1 -out ${tmpdir}/${prefix}/blast.result

#Inputファイルのヘッダを書き込み
echo -e "id\t${prefix}.fastq" > ${tmpdir}/${prefix}/${prefix}.input.tmp

#Inputファイル書き込み
cat ${tmpdir}/${prefix}/blast.result | awk '$3 > 100' | awk '$5 > 90' | awk '$6 / $3 > 0.9' | cut -f 1,16 | sort | uniq | cut -f 2 | sort | uniq -c | sort -r -n | awk 'BEGIN{OFS="\t"} {c="";for(i=2;i<=NF;i++) c=c $i" "; print c, $1}' >> ${tmpdir}/${prefix}/${prefix}.input.tmp

# inputファイルの修正
# python2 ${scriptdir}/create_input.py ${prefix} ${outputFileDirPath} ${fishname_ja_Path} ${tmpdir}
${singularity_path} run --bind ${outputFileDirPath}:${outputFileDirPath} ${workdir}/singularity_image/python_xlrd.sif python ${scriptdir}/create_input.py ${prefix} ${outputFileDirPath} ${fishname_ja_Path} ${tmpdir}
#docker run -i --rm -v ${outputFileDirPath}:${outputFileDirPath} -v ${workdir}:${workdir} -v ${workdir} -u `id -u`':'`id -g` c2997108/selenium-chrome:4.3.0_selenium_xlrd python3 ${scriptdir}/create_input.py ${prefix} ${outputFileDirPath} ${fishname_ja_Path} ${tmpdir}
