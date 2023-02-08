//准备关联数组
var fs = require("fs");
var arrSpnameSinica=fs.readFileSync('/System/Volumes/Data/home/2544842260/Public/addChineseName/spnameSinicaDB_SimplifedChinese_RoughlyManuallyInspected.txt');

arrSpnameSinica=(String(arrSpnameSinica)).split("\r\n");
var arrSpnameSinicaLength=arrSpnameSinica.length;


for (i=0;i<arrSpnameSinicaLength;i++) {
    arrSpnameSinica[i]=(String(arrSpnameSinica[i])).split(":");
};

var arrSpnameSinicaLength=arrSpnameSinica.length;


var dicSpnameSinica={};

for(i=0;i<arrSpnameSinicaLength;i++){
    dicSpnameSinica[arrSpnameSinica[i][1]]=arrSpnameSinica[i][0];
}
//console.log(dicSpnameSinica)

//读取文件
const args = process.argv.slice(2)
var fs = require("fs");
var imputFile=fs.readFileSync(args[0]);
imputFile=imputFile.toString('utf8');
imputFile=imputFile.split("\n");
var imputFileLength=imputFile.length;

if(imputFile[imputFileLength]==null){
    imputFile.pop();
}

imputFileLength=imputFile.length;
var resultTemp
for(i=0;i<imputFileLength;i++){
    if(imputFile[i].indexOf(".fastq")===-1){
        var fish=imputFile[i].split("\t");
        //console.log(fish)
        var fishname=fish[0];
        var value=fish[1]
        //console.log("学名="+fishname);
        //console.log("值="+value);
        //搜索
        var searchTemp=dicSpnameSinica[fishname];
        var fishnameTemp;
        if(searchTemp===undefined){
            //console.log(fishname+" not found Chinese name")
            fishnameTemp=fishname+"\t"+value;
            console.log(fishnameTemp)
        }else{
            fishnameTemp=searchTemp+":"+fishname+"\t"+value;
            console.log(fishnameTemp)
        }
    }else{
        console.log(imputFile[i]);
    }
    
    //fs.appendFileSync("mitooutput/"+args[0],fishnameTemp,'utf8');
}




