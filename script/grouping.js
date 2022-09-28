//node grouping.js inputFilePath
//read species file
const { group } = require("console");
const { Socket } = require("dgram");
var fs = require("fs");
var arg=process.argv.splice(2);
file=arg[0]
//var data = fs.readFileSync('/System/Volumes/Data/home/2544842260/Public/100again.txt');
var data = fs.readFileSync(file);
//change the data to 1D-array
var arr = data.toString().split("\n");
arr.sort();
var processList=[]
var speciesNumber=arr.length
var saveList=[]
//change the data to 2D-array
for (var species=0; species<speciesNumber; species++) {
    processList[species]=arr[species].split(";")
}

var countNumber=speciesNumber

//COUNTING the words, and separate the list
var round=0
do{
    var counttmp=[]
    var wordListtmp=[]
    for (var s=0; s<processList.length;s++){
        var existchecker="nonexist"
        for (i=0;i<wordListtmp.length;i++){
            if (processList[s][round]===wordListtmp[i]){
                existchecker="exist"
                var posilog=i
            }
        }
        if (existchecker=="exist"){
            counttmp[posilog]=counttmp[posilog]+1
        }
        else{
            wordListtmp.push(processList[s][round])
            counttmp.push(1)
        }
    }
    //get nost counted word
    var countNumbertmp=0
    for (var j=0; j<wordListtmp.length;j++){
        if(countNumbertmp<counttmp[j]){
            countNumbertmp=counttmp[j]
            var indexOfCountNumber=j
        }
        var mostCountedWord=wordListtmp[indexOfCountNumber]
    }
    //separate the species list if need
    if (countNumbertmp!==countNumber){
        //separate the list to save list and process list
        var savelisttmp=[]
        var processListtmp=[]
        processNumber=processList.length
        for (var k=0;k<processNumber;k++){
            if (mostCountedWord!==processList[k][round]){
                savelisttmp.push(processList[k])
            }
            else{
                processListtmp.push(processList[k])
            }
        }
        if (savelisttmp.length!==0){
            saveList.push(savelisttmp)
        }
        processList=processListtmp
    }
    countNumber=countNumbertmp
    var time=round+1
    //console.log("round "+time)
    //console.log(counttmp)
    //console.log(countNumber)
    //console.log(mostCountedWord)
    //console.log(saveList.length)
    //console.log(processList.length)
    //console.log(" ")
round=round+1
}
while (countNumber>(speciesNumber/8))


//get final separate list and counts
var separatedList=[]
separatedList.push(processList)
for (var q=0; q<saveList.length; q++){
    separatedList.push(saveList[q])
}

var separatedCountList=[]
for (var t=0; t<separatedList.length;t++){
    separatedCountList[t]=separatedList[t].length
}




//GROUPING
var operationseparatedCountList=separatedCountList
var operationseparatedList=separatedList
do{
    var groupinglisttmp=[]
    console.log("-------round-------")
    var groupingtmp=[]
    console.log("------"+groupinglisttmp.length)
    var d=speciesNumber
    var positionsaver=0
    for(var i=0;i<operationseparatedCountList.length;i++){
        var a=operationseparatedCountList[i]
        var b=operationseparatedCountList[i+1]
        var c=a+b
        if (c<d){
            d=c
            positionsaver=i
        }
    }
    console.log("----positionsaver----")
    console.log(positionsaver)
    console.log("----species number----")
    for (var j=0;j<positionsaver;j++){
        groupinglisttmp.push(operationseparatedList[j])
        console.log(operationseparatedList[j].length)
        console.log("------"+groupinglisttmp.length)
    }
    for (var s=0;s<operationseparatedList[positionsaver].length;s++){
        groupingtmp.push(operationseparatedList[positionsaver][s])
    }
    for (var s=0;s<operationseparatedList[positionsaver+1].length;s++){
        groupingtmp.push(operationseparatedList[positionsaver+1][s])
    }
    groupinglisttmp.push(groupingtmp)
    console.log("----combine----")
    console.log(groupingtmp.length)
    console.log("------"+groupinglisttmp.length)
    for (var j=positionsaver+2;j<operationseparatedCountList.length;j++){
        groupinglisttmp.push(operationseparatedList[j])
        console.log(operationseparatedList[j].length)
        console.log("------"+groupinglisttmp.length)
    }

    if (groupinglisttmp[-1]=undefined){
        groupinglisttmp.pop()
    }
    operationseparatedCountList=[]
    for (var t=0; t<groupinglisttmp.length;t++){
        operationseparatedCountList[t]=groupinglisttmp[t].length
    }
    console.log("----count now----")
    console.log(groupinglisttmp.length)
    console.log(operationseparatedCountList.length)
    console.log(operationseparatedCountList)
    operationseparatedList=groupinglisttmp

}
while(operationseparatedCountList.length>8)



console.log("----------RESULT----------")
console.log("-------counting result-------")
console.log(separatedCountList)

var groupingresult=operationseparatedList
console.log("-------grouping result-------")
for(var i=0;i<groupingresult.length;i++){
    console.log(groupingresult[i].length)
}
console.log(groupingresult.length)

// output file
var str=""
var strSingleLine=""
for (var i=0;i<groupingresult.length;i++){
    var colormark=i+1
    for (var j=0;j<groupingresult[i].length;j++){
        strSingleLine=groupingresult[i][j].toString();
        strSingleLine=strSingleLine+'\t'+colormark+'\n'
        str=str+strSingleLine
    }
}
str=str.replace(/,/g,";")
fs.writeFile("classifylist.txt",str,function(err){
    if(err){
        return console.log(err)
    }
})

//find commonness
var commonness=""
for (var g=0;g<groupingresult.length;g++){
    var commonnessWordPosi=0
    var commonnessWordCount=0
    var commonnessWordTemp=""
    console.log("--------"+"group"+(g+1))
    var commonnessStrTemp=""
    var commonnessTemp=""
    do{
        commonnessWordCount=0
        commonnessWordTemp=groupingresult[g][0][commonnessWordPosi]
        console.log(commonnessWordTemp)
        if (commonnessStrTemp==""){
            commonnessStrTemp=commonnessWordTemp
        }
        else{
            commonnessStrTemp=commonnessStrTemp+";"+commonnessWordTemp
        }

        for (var species=0;species<groupingresult[g].length;species++){
            if (groupingresult[g][species][commonnessWordPosi]==commonnessWordTemp){
                commonnessWordCount=commonnessWordCount+1
            }
        }
        console.log(commonnessWordCount)
        commonnessWordPosi=commonnessWordPosi+1
        if (commonnessWordCount!=groupingresult[g].length){
            console.log(commonnessStrTemp)
            //the last word is not common word, so remove it.
            commonnessTemp=commonnessStrTemp.substring(0,commonnessStrTemp.lastIndexOf(";"))
            console.log(commonnessTemp)
            commonness=commonness+(g+1)+'\t'+commonnessTemp+'\n'
        }
        
    }
    while (commonnessWordCount==groupingresult[g].length)
}
fs.writeFile("commonness.txt",commonness,function(err){
    if(err){
        return console.log(err)
    }
})
