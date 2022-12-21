#!/bin/bash

#このスクリプトでは、学名を和名に変換するデータベースを生成する。inputするファイルは鹿児島大学の日本産魚類全種リストを用いる（https://www.museum.kagoshima-u.ac.jp/staff/motomura/jaf.html）
if [ "$1" = "" ]; then echo 'USAGE: bash '$0' <input.url  #https://www.museum.kagoshima-u.ac.jp/staff/motomura/20221121_JAFList.xlsx>'; exit ;fi

set -ex
unset LC_ALL

# フォルダ等の設定を読み込み
sdir=$(dirname `readlink -f "$0" || echo "$0"`)
source "$sdir"/config.sh

#データベースのダウンロード
wget -O /tmp/specieslist.xlsx $1

#xlsx2csvのインストール
#pip install --user xlsx2csv

#xlsxをcsvに変換し、学名・和名・科名だけを抽出。
xlsx2csv -e -d tab /tmp/specieslist.xlsx |awk -F"\t" '{if($4!="和名なし")print $4"\t"$5"\t"$2;}' > $workdir/db/scientificname2japanesename_complete.csv

#欠落している種を手動で追加
cat $workdir/db/additional_species_complete.csv >> $workdir/db/scientificname2japanesename_complete.csv
