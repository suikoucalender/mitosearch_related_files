#!/bin/bash

source ~/.bashrc

# フォルダ等の設定を読み込み
sdir=$(dirname `readlink -f "$0" || echo "$0"`)
source "$sdir"/config.sh

# 引数
id="$1"

#Singularityのイメージがなければ、githubのリリースから取ってくる。ファイルサイズが大きいのでソースコードには含められない。
if [ ! -e "${workdir}/singularity_image/sratoolkit.sif" ]; then
 wget -O "${workdir}/singularity_image/sratoolkit.sif" https://github.com/suikoucalender/mitosearch_related_files/releases/download/0.01/sratoolkit.sif
fi

# エラーが発生したら終了+コマンド表示+パイプ途中でエラーの場合もエラーにする
set -ex
set -o pipefail

# FASTQダウンロード
${singularity_path} run -B ${workdir}/fastq/ ${workdir}/singularity_image/sratoolkit.sif fastq-dump ${id} --gzip --split-files --outdir ${workdir}/fastq/

# 新しく取得したSRA番号のメタデータを取得
set +x

a=$(curl https://www.ncbi.nlm.nih.gov/biosample/`curl "https://www.ncbi.nlm.nih.gov/sra/?term=$id"|grep SAM|sed 's/SAM/\nSAM/g;'|sed 's/".*//; s/<.*//; s/ .*//'|grep "^SAM"|awk 'NR==1{print $0}'`)
set +o pipefail
lat="$id"$'\t'`echo "$a"|grep -i latitude|sed 's/<[^>]*>/\t/g'|sed 's/\t\+/\n/g'|grep -A 1 latitude|tail -n 1`$'\t'`echo "$a"|
 grep -i "collection date"|sed 's/<[^>]*>/\t/g'|sed 's/\t\+/\n/g'|grep -A 1 -i "collection date"|tail -n 1`
long="$id"$'\t'`echo "$a"|grep -i longitude|sed 's/<[^>]*>/\t/g'|sed 's/\t\+/\n/g'|grep -A 1 longitude|tail -n 1`$'\t'`echo "$a"|
 grep -i "collection date"|sed 's/<[^>]*>/\t/g'|sed 's/\t\+/\n/g'|grep -A 1 -i "collection date"|tail -n 1`

str=$lat
latitude=(`echo $lat`)
longitude=(`echo $long`)

if [[ $lat == $long ]]; then
    :
else
    if [ `echo "${latitude[1]} > 0.0" | bc` == 1 ]; then
        lat=${latitude[1]}" N"
    else
        lat=`echo ${latitude[1]}| sed 's/^-//'`" S"
    fi

    if [ `echo "${longitude[1]} > 0.0" | bc` == 1 ]; then
        long=${longitude[1]}" E"
    else
        long=`echo ${longitude[1]}| sed 's/^-//'`" W"
    fi
    str=`echo -e ${latitude[0]}'\t'$lat" "$long'\t'${latitude[2]}`
fi
set -x

# 同一マシン内での排他制御をしつつ経度緯度を書き込む
flock -x /tmp/mitolock bash -c "echo '$str' >> ${workdir}/data/lat-long-date.txt"

# inputFile作成
qsub -j Y -N mitoupda -o $workdir/tmp/$id.log "$sdir"/qsubsh8 bash "$sdir"/create_input.sh ${id}
