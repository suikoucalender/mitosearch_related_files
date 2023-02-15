#！/bin/bash
path=input/.
files=$(ls $path)

for filename in $files
do
    node createFiles.js input/$filename > output/$filename
done


