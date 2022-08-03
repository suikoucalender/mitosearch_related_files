#!/bin/bash

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
${singularity_path} run ${workdir}/singularity_image/sratoolkit.sif fastq-dump ${id} --gzip --split-files --outdir ${workdir}/fastq/

# 新しく取得したSRA番号のメタデータを取得
set +x
a=$(curl https://www.ncbi.nlm.nih.gov/biosample/`curl "https://www.ncbi.nlm.nih.gov/sra/?term=$id"|grep SAM|sed 's/SAM/\nSAM/g;'|sed 's/".*//; s/<.*//; s/ .*//'|grep "^SAM"|awk 'NR==1{print $0}'`)
set +o pipefail
str="$id"$'\t'`echo "$a"|grep -i lat|grep -i long|sed 's/<[^>]*>/\t/g'|sed 's/\t\+/\n/g'|grep -A 1 long|tail -n 1`$'\t'`echo "$a"|
 grep -i "collection date"|sed 's/<[^>]*>/\t/g'|sed 's/\t\+/\n/g'|grep -A 1 -i "collection date"|tail -n 1`
set -x

# 同一マシン内での排他制御をしつつ経度緯度を書き込む
flock -x /tmp/mitolock bash -c "echo '$str' >> ${workdir}/data/lat-long-date.txt"

# inputFile作成
qsub -j Y -N mitoupda -o $workdir/tmp/$id.log "$sdir"/qsubsh8 bash "$sdir"/create_input.sh ${id}
