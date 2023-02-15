#！/bin/bash

while read line
do 
    fishname=${line}
    sleep 1s
    node nameSearchingWithSinicaDB.js ${fishname} >> /System/Volumes/Data/home/2544842260/Public/addChineseName/spnameSinica.txt
done < spname.txt