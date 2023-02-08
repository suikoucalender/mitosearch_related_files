#！/bin/bash
path=mitoinput/.
files=$(ls $path)

for filename in $files
do
    node createFiles.js mitoinput/$filename > /System/Volumes/Data/home/2544842260/Public/addChineseName/mitoSinicaName/$filename
done


