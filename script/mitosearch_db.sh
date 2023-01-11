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
# download_fastq.shの中でlat-long-date.txtにも情報が追加される
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

# 円グラフが日付順にでてくるように日付でソート
sort -t$'\t' -k3,3 -k1,1V ${workdir}/data/lat-long-date.txt > ${workdir}/data/lat-long-date.txt.tmp
mv ${workdir}/data/lat-long-date.txt.tmp ${workdir}/data/lat-long-date.txt

# テスト環境にデータをコピー
cp -p ${workdir}/inputFiles/*.input ${mitosearch_dev_db}
cp -p ${workdir}/data/lat-long-date.txt ${metadataDir_dev}
# 本番環境にデータをコピー
cp -p ${workdir}/inputFiles/*.input ${mitosearch_db}
cp -p ${workdir}/data/lat-long-date.txt ${metadataDir}
# inputFileを削除
#rm -f ${workdir}/inputFiles/*.input

# 陸のサンプルを弾く処理
## metadataを作業ディレクトリにコピー
cp -p  ${metadataDir}/mapwater.result ${workdir}/data/ || true

## データ更新
touch ${workdir}/data/mapwater.result
cat ${workdir}/data/lat-long-date.txt |
 awk -F'\t' '$2~"^[0-9]"{split($2,arr," "); if(arr[2]=="N"){k=arr[1]}else{k=-arr[1]}; if(arr[4]=="E"){k2=arr[3]}else{k2=-arr[3]}; if(flag[k":"k2]==0){flag[k":"k2]=1; print $1"\t"k"\t"k2}}'|
 awk -F'\t' 'FILENAME==ARGV[1]{a[$1]=1} FILENAME==ARGV[2]&&a[$2" "$3]==0{print $0}' <(awk -F'\t' '{split($1,arr,":"); split($2,arr2," "); print arr[2]"\t"arr2[1]}' ${workdir}/data/mapwater.result) /dev/stdin |
 awk '{print "echo -e \\\""$1":"$2" "$3"\t`docker run -v '$sdir':'$sdir' -w '$sdir'  -i --rm c2997108/python:3.10-staticmap_2 mapwater.py "$3" "$2"`\\\""}'|xargs -I{} bash -c "{}"|
 awk -F'\t' '$2!=""{print $0}' > ${workdir}/data/mapwater.result.new
cat ${workdir}/data/mapwater.result.new >> ${workdir}/data/mapwater.result
rm -f ${workdir}/data/mapwater.result.new
cat ${workdir}/data/lat-long-date.txt |
 awk -F'\t' '$2~"^[0-9]"{split($2,arr," "); if(arr[2]=="N"){k=arr[1]}else{k=-arr[1]}; if(arr[4]=="E"){k2=arr[3]}else{k2=-arr[3]}; print $1"\t"k" "k2}'|
 awk -F'\t' '
  FILENAME==ARGV[1]{data[$1]=$2}
  FILENAME==ARGV[2]{print $1"\t"data[$2]}
 ' <(awk -F'\t' '{split($1,arr,":"); split($2,arr2," "); print arr[2]"\t"arr2[1]}' ${workdir}/data/mapwater.result) /dev/stdin > ${workdir}/data/mapwater.result.txt

##テスト＆本番環境に反映
cp -p ${workdir}/data/mapwater.result.txt ${workdir}/data/mapwater.result ${metadataDir_dev}
cp -p ${workdir}/data/mapwater.result.txt ${workdir}/data/mapwater.result ${metadataDir}


#push to git
cd ${mitosearch_dev_path}
git pull
git add .
git commit -m "update database monthly"
git push
