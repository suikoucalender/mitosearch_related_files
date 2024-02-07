#!/bin/bash

#container=podman #docker or podman

source ~/.bashrc

#手動実行する場合
#/usr/bin/bash /home/yoshitake/mitosearch_related_files/script/mitosearch_db.sh 2>&1 | tee /home/yoshitake/mitosearch_related_files/log/$(date "+%Y%m%d-%H%M").log
#全データを再解析するときは、${workdir}/data/lat-long-date.txtを消してからファイルを作って実行すればOK
#有効なデータ件数を大雑把に知りたい場合
#more ../data/lat-long-date.txt |sort -k2,2|awk -F'\t' '$2~"^[0-9]"'|sort -t$'\t' -k3,3|awk -F'\t' '$3~"^[0-9]"'|wc -l

# フォルダ等の設定を読み込み
sdir=$(dirname `readlink -f "$0" || echo "$0"`)
source "$sdir"/config.sh

#Singularityのイメージがなければ、githubのリリースから取ってくる。ファイルサイズが大きいのでソースコードには含められない。 for create_input.sh
if [ ! -e "${workdir}/singularity_image/flash.sif" ]; then
 wget -O "${workdir}/singularity_image/flash.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/flash.sif
fi
if [ ! -e "${workdir}/singularity_image/cutadapt.sif" ]; then
 wget -O "${workdir}/singularity_image/cutadapt.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/cutadapt.sif
fi
if [ ! -e "${workdir}/singularity_image/python_xlrd.sif" ]; then
 wget -O "${workdir}/singularity_image/python_xlrd.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/python_xlrd.sif
fi
if [ ! -e "${workdir}/singularity_image/seqkit.sif" ]; then
 wget -O "${workdir}/singularity_image/seqkit.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/seqkit.sif
fi
#Singularityのイメージがなければ、githubのリリースから取ってくる。ファイルサイズが大きいのでソースコードには含められない。 for download_fastq.sh
if [ ! -e "${workdir}/singularity_image/sratoolkit.sif" ]; then
 wget -O "${workdir}/singularity_image/sratoolkit.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/sratoolkit.sif
fi
#Singularityのイメージがなければ、githubのリリースから取ってくる。ファイルサイズが大きいのでソースコードには含められない。 for mitosearch_db.sh & create_input.sh
if [ ! -e "${workdir}/singularity_image/ncbi_blast:2.13.0.sif" ]; then
 wget -O "${workdir}/singularity_image/ncbi_blast:2.13.0.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/ncbi_blast_2.13.0.sif
fi
#Singularityのイメージがなければ、githubのリリースから取ってくる。ファイルサイズが大きいのでソースコードには含められない。 for mitosearch_db.sh
if [ ! -e "${workdir}/singularity_image/c2997108_python_3.10-staticmap_2.sif" ]; then
 wget -O "${workdir}/singularity_image/c2997108_python_3.10-staticmap_2.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/c2997108_python_3.10-staticmap_2.sif
fi


# エラーが発生したら終了+コマンド表示
set -ex

# git pullで拾ってこないディレクトリを無ければ作る
#mkdir -p $mitosearch_path/db_fish_ja $mitosearch_path/db_fish_zh $mitosearch_path/db_fish_en
mkdir -p ${workdir}/data
mkdir -p ${workdir}/download
mkdir -p ${workdir}/fastq
mkdir -p ${workdir}/tmp
mkdir -p ${workdir}/blastresult
mkdir -p ${workdir}/inputFiles/db_fish_ja ${workdir}/inputFiles/db_fish_zh ${workdir}/inputFiles/db_fish_en

# Backupを取得 本番環境のほうをバックアップ
timestamp=$(date "+%Y%m%d-%H%M")
mkdir -p ${workdir}/backup/${timestamp}/inputFiles
cp -rp "${mitosearch_path}"/db_fish* ${workdir}/backup/${timestamp}/inputFiles || true
cp -rp "${mitosearch_path}"/data/fish ${workdir}/backup/${timestamp} || true
# 新しくデータをダウンロードする前に現在のダウンロードリストをバックアップ
cp -rp ${workdir}/data ${workdir}/backup/${timestamp}/workfile

# MiFishプライマーでヒットしたSRA番号のリストを取得
#$container run -t --rm ncbi/blast:2.13.0 bash -c "esearch -db sra -query mifish|efetch -format runinfo" | cut -f 1 -d , |grep -v "^Run$" > ${workdir}/download/SraAccList.txt.temp1
#$container run -t --rm ncbi/blast:2.13.0 bash -c "esearch -db bioproject -query mifish|efetch -format native" |grep "^BioProject Accession:"|awk '{print $3}'|while read i; do
# $container run -t --rm ncbi/blast:2.13.0 bash -c "esearch -db sra -query $i|efetch -format runinfo"
#done | cut -f 1 -d , |grep -v "^Run$" > ${workdir}/download/SraAccList.txt.temp2
$singularity_path exec ${workdir}/singularity_image/ncbi_blast:2.13.0.sif bash -c "esearch -db sra -query mifish|efetch -format runinfo" |
 cut -f 1 -d , |grep -v "^Run$" > ${workdir}/download/SraAccList.txt.temp1
$singularity_path exec ${workdir}/singularity_image/ncbi_blast:2.13.0.sif bash -c "esearch -db bioproject -query mifish|efetch -format native" | grep "^BioProject Accession:"|awk '{print $3}' > ${workdir}/download/SraAccList.txt.temp2p
#cat ${workdir}/download/SraAccList.txt.temp2p|while read i; do #これだとsingularityでは1データ目だけ実行して終わってしまう
#  $singularity_path exec ${workdir}/singularity_image/ncbi_blast:2.13.0.sif bash -c "esearch -db sra -query $i|efetch -format runinfo"
# done | cut -f 1 -d , |grep -v "^Run$" > ${workdir}/download/SraAccList.txt.temp2
cat ${workdir}/download/SraAccList.txt.temp2p|xargs -I{} bash -c "$singularity_path exec ${workdir}"'/singularity_image/ncbi_blast:2.13.0.sif bash -c "esearch -db sra -query {}|efetch -format runinfo"'|
 cut -f 1 -d , |grep -v "^Run$" > ${workdir}/download/SraAccList.txt.temp2
cat ${workdir}/download/SraAccList.txt.temp1 ${workdir}/download/SraAccList.txt.temp2 |sort|uniq > ${workdir}/download/SraAccList.txt

# lat-long-date.txtから既にダウンロードされているサンプルのSRA番号を取得
cat ${workdir}/data/lat-long-date.txt | cut -f 1 > ${workdir}/data/exist_samples.txt

# 新しく取得したSRA番号のみを取得
awk -F'\t' 'FILENAME==ARGV[1]&&$1!=""{n++; a[$1]=1} FILENAME==ARGV[2]&&$1!=""{if(a[$1]!=1){print $0; m++}else{k++}}
 END{print "new: "m", exist: "k", total (old + new): "n+m > "/dev/stderr"}' ${workdir}/data/exist_samples.txt ${workdir}/download/SraAccList.txt > ${workdir}/data/new_samples.txt

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

## テスト環境にデータをコピー
#rsync -av ${workdir}/inputFiles/db_fish* ${mitosearch_dev_path}/
#cp -p ${workdir}/data/lat-long-date.txt ${metadataDir_dev}
# 本番環境にデータをコピー
rsync -av ${workdir}/inputFiles/db_fish* ${mitosearch_path}/
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
 awk '{print "echo -e \\\""$1":"$2" "$3"\t`'"$singularity_path"' exec -B '"$sdir"' '"${workdir}/singularity_image/c2997108_python_3.10-staticmap_2.sif /usr/local/bin/python "' '"$sdir"'/mapwater.py "$3" "$2"`\\\""}'|xargs -I{} bash -c "{}"|
 awk -F'\t' '$2!=""{print $0}' > ${workdir}/data/mapwater.result.new
 #awk '{print "echo -e \\\""$1":"$2" "$3"\t`docker run -v '$sdir':'$sdir' -w '$sdir'  -i --rm c2997108/python:3.10-staticmap_2 mapwater.py "$3" "$2"`\\\""}'|xargs -I{} bash -c "{}"|
cat ${workdir}/data/mapwater.result.new >> ${workdir}/data/mapwater.result
rm -f ${workdir}/data/mapwater.result.new
cat ${workdir}/data/lat-long-date.txt |
 awk -F'\t' '$2~"^[0-9]"{split($2,arr," "); if(arr[2]=="N"){k=arr[1]}else{k=-arr[1]}; if(arr[4]=="E"){k2=arr[3]}else{k2=-arr[3]}; print $1"\t"k" "k2}'|
 awk -F'\t' '
  FILENAME==ARGV[1]{data[$1]=$2}
  FILENAME==ARGV[2]{print $1"\t"data[$2]}
 ' <(awk -F'\t' '{split($1,arr,":"); split($2,arr2," "); print arr[2]"\t"arr2[1]}' ${workdir}/data/mapwater.result) /dev/stdin > ${workdir}/data/mapwater.result.txt

##テスト＆本番環境に反映
#cp -p ${workdir}/data/mapwater.result.txt ${workdir}/data/mapwater.result ${metadataDir_dev}
cp -p ${workdir}/data/mapwater.result.txt ${workdir}/data/mapwater.result ${metadataDir}


#push to git
#cd ${mitosearch_dev_path}
#git pull
#git add .
#git commit -m "update database monthly"
#git push
