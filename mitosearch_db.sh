#!/bin/bash

# ------------

# 作業ディレクトリを指定
workdir=/home/yoshitake/mitosearch_update_db

# inputFileを格納しているディレクトリ
mitosearch_db=/home/yoshitake/mitosearch_db/db_fish

# metadataを格納しているディレクトリ
metadataDir=/home/yoshitake/mitosearch/Mitosearch/data/fish
metadataDir_dev=/home/yoshitake/mitosearch_dev/Mitosearch/data/fish

# singularityのPATH
singularity_path=/home/yoshitake/tool/singularity-3.5.2/bin/singularity

#projectのPATH
mitosearch_path=/home/yoshitake/mitosearch/Mitosearch

# ------------

# エラーが発生したら終了
set -e

# Backupを取得
timestamp=$(date "+%Y%m%d-%H%M")
mkdir ${workdir}/backup/${timestamp}
mkdir ${workdir}/backup/${timestamp}/inputFiles
cp ${mitosearch_db}/*.input ${workdir}/backup/${timestamp}/inputFiles
cp -r ${metadataDir} ${workdir}/backup/${timestamp}

# metadataを作業ディレクトリにコピー
cp  ${metadataDir}/lat-long-date.txt ${workdir}/data

# 過去のメタデータを削除
if [ -e ${workdir}/download/SraAccList.txt ]; then
    rm -f ${workdir}/download/SraAccList.txt
fi

# MiFishプライマーでヒットしたSRA番号のリストを取得
${singularity_path} exec ${workdir}/singularity_image/selenium_client.sif  python ${workdir}/script/download_metadata.py

# lat-long-date.txtから既にダウンロードされているサンプルのSRA番号を取得
cat ${workdir}/data/lat-long-date.txt | cut -f 1 > ${workdir}/data/exist_samples.txt

# 新しく取得したSRA番号のみを取得
sort ${workdir}/download/SraAccList.txt ${workdir}/data/exist_samples.txt ${workdir}/data/exist_samples.txt | uniq -u > ${workdir}/data/new_samples.txt

# 新しくダウンロードされたファイルの情報などを取得
cp -r ${workdir}/data ${workdir}/backup/${timestamp}/workfile

# FASTQダウンロードとinputFile作成
IFS=$'\n'

set +e
for id in `cat ${workdir}/data/new_samples.txt`
do
    # FASTQダウンロード
    ${singularity_path} run ${workdir}/singularity_image/sratoolkit.sif fastq-dump ${id} --gzip --split-files --outdir ${workdir}/fastq/

    # prefetchされた.sraファイルを削除
    rm -f ~/ncbi/public/sra/${id}.sra

    if [ -e ${workdir}/fastq/${id}_1.fastq.gz ]; then
        # inputFile作成
        bash ${workdir}/script/create_input.sh ${id}

        # 新しく取得したSRA番号のメタデータを取得
        a=$(curl https://www.ncbi.nlm.nih.gov/biosample/`curl "https://www.ncbi.nlm.nih.gov/sra/?term=$id"|grep SAM|sed 's/SAM/\nSAM/g;'|sed 's/".*//; s/<.*//; s/ .*//'|grep "^SAM"|head -n 1`)
        echo "$id"$'\t'`echo "$a"|grep -i lat|grep -i long|sed 's/<[^>]*>/\t/g'|sed 's/\t\+/\n/g'|grep -A 1 long|tail -n 1`$'\t'`echo "$a"|grep -i "collection date"|sed 's/<[^>]*>/\t/g'|sed 's/\t\+/\n/g'|grep -A 1 -i "collection date"|tail -n 1` >> ${workdir}/data/lat-long-date.txt
    fi

    # シーケンスファイルとtmpデータを削除
    rm -rf ${workdir}/tmp/*
    rm -f ${workdir}/fastq/*.gz
done
set -e

# テスト環境にデータをコピー
cp ${workdir}/data/lat-long-date.txt ${metadataDir_dev}
# 本番環境にデータをコピー
cp ${workdir}/inputFiles/*.input ${mitosearch_db}
cp ${workdir}/data/lat-long-date.txt ${metadataDir}
# inputFileを削除
rm -f ${workdir}/inputFiles/*.input

#push to git
cd ${mitosearch_path}
git add .
git commit -m "update database monthly"
git push -u origin main
