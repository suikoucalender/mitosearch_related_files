#!/bin/bash

# フォルダ等の設定を読み込み
sdir=$(dirname `readlink -f "$0" || echo "$0"`)
source "$sdir"/config.sh

# エラーが発生したら終了+コマンド表示
set -ex

# git pullで拾ってこないディレクトリを無ければ作る
mkdir -p $mitosearch_db
mkdir -p ${workdir}/data
mkdir -p ${workdir}/download
mkdir -p ${workdir}/fastq
mkdir -p ${workdir}/tmp
mkdir -p ${workdir}/inputFiles

# Backupを取得 本番環境のほうをバックアップ
timestamp=$(date "+%Y%m%d-%H%M")
mkdir -p ${workdir}/backup/${timestamp}/inputFiles
cp -rp ${mitosearch_db}/*.input ${workdir}/backup/${timestamp}/inputFiles || true
cp -rp ${metadataDir} ${workdir}/backup/${timestamp} || true

# metadataを作業ディレクトリにコピー
cp -p  ${metadataDir}/lat-long-date.txt ${workdir}/data/ || true

# 過去のメタデータを削除
#if [ -e ${workdir}/download/SraAccList.txt ]; then
#    rm -f ${workdir}/download/SraAccList.txt
#fi

# MiFishプライマーでヒットしたSRA番号のリストを取得
docker run -i --rm -v "$workdir":"$workdir" -w "$workdir" c2997108/selenium-chrome:4.3.0_selenium_xlrd bash ${workdir}/script/download_metadata.sh
mv ${workdir}/SraAccList.txt ${workdir}/download/SraAccList.txt

# lat-long-date.txtから既にダウンロードされているサンプルのSRA番号を取得
cat ${workdir}/data/lat-long-date.txt | cut -f 1 > ${workdir}/data/exist_samples.txt

# 新しく取得したSRA番号のみを取得
#sort ${workdir}/download/SraAccList.txt ${workdir}/data/exist_samples.txt ${workdir}/data/exist_samples.txt | uniq -u > ${workdir}/data/new_samples.txt
awk -F'\t' 'FILENAME==ARGV[1]&&$1!=""{n++; a[$1]=1} FILENAME==ARGV[2]&&$1!=""{if(a[$1]!=1){print $0; m++}else{k++}}
 END{print "new: "m", exist: "k", total (old + new): "n+m > "/dev/stderr"}' ${workdir}/data/exist_samples.txt ${workdir}/download/SraAccList.txt > ${workdir}/data/new_samples.txt

# 新しくダウンロードされたファイルの情報などを取得
cp -rp ${workdir}/data ${workdir}/backup/${timestamp}/workfile

# FASTQダウンロードとinputFile作成 xargsを使って5つ並列実行
IFS=$'\n'

set +e
for id in `cat ${workdir}/data/new_samples.txt`
do
    echo bash "$sdir"/download_fastq.sh "$id"
done|xargs -I{} -P 5 bash -c "{}"
set -e

while [ `qstat|grep mitoupda|wc -l` -gt 0 ]; do
 sleep 10
done

# テスト環境にデータをコピー
cp -p ${workdir}/inputFiles/*.input ${mitosearch_dev_db}
cp -p ${workdir}/data/lat-long-date.txt ${metadataDir_dev}
# 本番環境にデータをコピー
cp -p ${workdir}/inputFiles/*.input ${mitosearch_db}
cp -p ${workdir}/data/lat-long-date.txt ${metadataDir}
# inputFileを削除
#rm -f ${workdir}/inputFiles/*.input

#push to git
cd ${mitosearch_dev_path}
git pull
git add .
git commit -m "update database monthly"
git push
