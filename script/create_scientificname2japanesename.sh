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

#xlsxをcsvに変換し、学名と和名だけを抽出。

#学名に関して、属名と種小名の2単語のみを抽出したDBの作成
#セル内カンマ、セル内改行に対応させるためawk FPAT, nextを使う
xlsx2csv /tmp/specieslist.xlsx | awk -v FPAT='[^,]*|"[^"]+"' '{
  l=l$0;if(l!=""&&split(l,t,"\"")%2==0){l=l" ";next};$0=l;l=""; for(i=1;i<=NF;i++){sub("^\"","",$i); sub("\"$","",$i)};
  if($4!="和名なし"){split($5,array," "); print $4"\t"array[1]" "array[2]}
 }' > $workdir/db/scientificname2japanesename_2words.csv

#学名に関して、３単語以上の場合においても全てを抽出したDBの作成
#セル内カンマ、セル内改行に対応させるためawk FPAT, nextを使う
xlsx2csv /tmp/specieslist.xlsx | awk -v FPAT='[^,]*|"[^"]+"' '{
  l=l$0;if(l!=""&&split(l,t,"\"")%2==0){l=l" ";next};$0=l;l=""; for(i=1;i<=NF;i++){sub("^\"","",$i); sub("\"$","",$i)};
  if($4!="和名なし"){print $4"\t"$5}
 }' > $workdir/db/scientificname2japanesename_complete.csv

#欠落している種を手動で追加
cat $workdir/db/additional_species_2words.csv >> $workdir/db/scientificname2japanesename_2words.csv
cat $workdir/db/additional_species_complete.csv >> $workdir/db/scientificname2japanesename_complete.csv
