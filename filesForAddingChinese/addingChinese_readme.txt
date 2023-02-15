Steps for Adding Chinese name into [*.input files]
1. Run [bash readSPname.sh] to read File spname.txt line by line, [nameSearchingWithSinicaDB.js] to match the Chinese name with the scientific name.
Then we can get [spnameSinica.txt], which contains Chinese names used in China Mainland and scientific names and looks like “中文名:scientific name”.
Copy and paste the content into the traditional and simplified conversion tool, which can convert most of the traditional characters into simplified characters.

Note: 
a. The book, Latin-Chinese Dictionary of Fish Name by Classification System, was jointly published in Taiwan by Shanghai Ocean University and Academia Sinica, Therefore, the characters used are traditional Chinese characters.

b. The trouble is that some Chinese characters were not digitized a decade ago, so this database uses images directly for display. The Chinese names obtained will be partially missing in this case. 
In addition, some Chinese characters were not displayed correctly on the web page, so the obtained Chinese characters are also mojibake.
I think this can only be fixed by manual visual inspection.

c. Traditional and simplified conversion tools can be easily found on the Internet, 
for example:
https://www.aies.cn/.
But fish names occasionally use rarely-used Chinese characters. So conversion tools are not foolproof. There are some Chinese characters that need to be converted manually, too.


2. Run [bash readInputFile.sh] to read [input files] file by file and line by line. [createFiles.js] will prepare a dictionary array based on [spnameSinica.txt] we get before. Every line in [*.input files] will be searched with the dictionary. Then the results will be printed into corresponding files.





Steps for Adding Chinese name into [classifylist.txt file]
Run [node classifylistAddChinese.js > classifylist_zh.txt], [classifylist_plain.txt] will be split into an array, then searched with the dictionary based on [spnameSinica.txt].

