const Decimal = require('./decimal.js');
const args = process.argv.slice(2)
const fs = require('fs');
const path = require('path');

const locationPath = args[0];
const imputFolderPath = args[1];
var blockSize = new Decimal(args[2]);
var lang = imputFolderPath.slice(-2);

// read lat-long-date.txt file
var locationInfo;
locationInfo=fs.readFileSync(locationPath,'utf8');
locationInfo=locationInfo.split('\n');
removeEmptyLastItem(locationInfo);
for(var i=0;i<locationInfo.length;i++){
    locationInfo[i]=locationInfo[i].split('\t');
    locationInfo[i][1]=locationInfo[i][1].split(' ') 
}

//Delete missing or abnormal latitude and longitude data
for (let i = locationInfo.length - 1; i >= 0; i--) {
    if (locationInfo[i][1][0]==="" || locationInfo[i][1].length!==4 || isNaN(locationInfo[i][1][0])) {
        locationInfo.splice(i, 1);
    }
}


//Convert latitude and longitude to digital format
for(var i=0;i<locationInfo.length;i++){
    locationInfo[i][1][0]=parseFloat(locationInfo[i][1][0])
    if(locationInfo[i][1][1]==="S"){
        locationInfo[i][1][0]=-locationInfo[i][1][0]
        locationInfo[i][1][0]=new Decimal(locationInfo[i][1][0])
    }
    locationInfo[i][1][1]=Decimal.mul(Decimal.floor(Decimal.div(locationInfo[i][1][0], blockSize)),blockSize)
    locationInfo[i][1][2]=parseFloat(locationInfo[i][1][2])
    if(locationInfo[i][1][3]==="W"){
        locationInfo[i][1][2]=-locationInfo[i][1][2]
        locationInfo[i][1][2]=new Decimal(locationInfo[i][1][2])
    }
    locationInfo[i][1][3]=Decimal.mul(Decimal.floor(Decimal.div(locationInfo[i][1][2], blockSize)),blockSize)
}
//console.log(locationInfo)//looks like [filename,[lat,blocklat,lng,blocklng],time]

//prepare block information
var blockInfo={}
for(var i=0;i<locationInfo.length;i++){
    var filenametemp=locationInfo[i][0]
    var blocklattemp=locationInfo[i][1][1]
    var blocklngtemp=locationInfo[i][1][3]
    var key=`${blocklattemp},${blocklngtemp}`
    if (!blockInfo[key]) {
        blockInfo[key] = [filenametemp];
    } else {
        blockInfo[key].push(filenametemp);
    }
    
}
//console.log(blockInfo)//looks like {`blocklat,blocklng`:fileName}
var blockname=Object.keys(blockInfo)

// reading .input files and Integrating location Info
var data={}
for(var i=0;i<locationInfo.length;i++){
    var datatemp=[]
    var inputFileID=locationInfo[i][0]
    var inputFileName=inputFileID+".input"
    var inputFilePath=`${imputFolderPath}/${inputFileName}`
    var species = {}
    var tempSpecies
    if (!fs.existsSync(inputFilePath)) {
        //console.log(`${inputFileID}.input does not exist. Skipping...`);
        continue; // Skip to next iteration if file does not exist
    }
    datatemp.push(locationInfo[i][1][0]);//lat
    datatemp.push(locationInfo[i][1][2]);//long
    datatemp.push(locationInfo[i][2]);//time
    //read files
    tempSpecies=fs.readFileSync(inputFilePath,'utf8');
    //convert to array
    tempSpecies=tempSpecies.split('\n');
    //remove the first item and empty last item
    tempSpecies.splice(0, 1);
    removeEmptyLastItem(tempSpecies);
    //Organize into associative arrays
    for(var j=0;j<tempSpecies.length;j++){
        tempSpecies[j]=tempSpecies[j].split('\t');
        species[tempSpecies[j][0]]=new Decimal(tempSpecies[j][1]);//改成decimal之后会出问题
    }
    datatemp.push(species);
    data[inputFileID]=datatemp
}
//console.log(data)

//follow the block information, prepare pie data
for(x=0;x<blockname.length;x++){//loop for each block
    var blocknamearray=blockname[x].split(',')
    var samplenumber=blockInfo[blockname[x]].length
    var blockSpeciesTemp=[]
    var blockRatioTemp=[]
    var sumLat=new Decimal(0)
    var sumLong=new Decimal(0)
    var averageLat
    var averageLong
    console.log("--------------------------("+blocknamearray+")--------------------------")
    for(s=0;s<blockInfo[blockname[x]].length;s++){//loop for each file
        var filename=blockInfo[blockname[x]][s]
        var fileSpeciesData=data[filename]
        var fileSpeciesNameTemp
        var fileSpeciesRatioTemp=[]
        if(fileSpeciesData!==undefined){
            //record species ratio in file
            fileSpeciesNameTemp=Object.keys(fileSpeciesData[3])
            for(y=0;y<fileSpeciesNameTemp.length;y++){//loop for each species
                fileSpeciesRatioTemp[y]=new Decimal(fileSpeciesData[3][fileSpeciesNameTemp[y]])
            }
            //console.log(fileSpeciesNameTemp)
            //console.log(fileSpeciesRatioTemp)
            //record pie location
            sumLat=Decimal.add(sumLat,fileSpeciesData[0])
            sumLong=Decimal.add(sumLong,fileSpeciesData[1])
            //calculate the ratio of each fish in one block
            blockSpeciesTemp.push(fileSpeciesNameTemp)
            blockRatioTemp.push(fileSpeciesRatioTemp)
        }
        

    }
    averageLat=Decimal.div(sumLat,samplenumber)//pie chart location
    averageLong=Decimal.div(sumLong,samplenumber)
    //console.log(blockSpeciesTemp)
    //console.log(blockRatioTemp)
    //console.log("average lat",averageLat)
    //console.log("average lng",averageLong)
    //console.log("sample number",samplenumber)
    //console.log(blockSpeciesTemp.length)

    //calcutate the ratio of each species in each block
    if(blockSpeciesTemp.length!==0){//some sample is in lat-lng-date.txt file, but there were no input file, remove them in this step.
        var pieInputList=[]
        var pieCoord=[averageLat,averageLong,samplenumber]
        var pieInputListTemp={}//{fishname:ratio}
        for(i=0;i<blockSpeciesTemp.length;i++){
            for(j=0;j<blockSpeciesTemp[i].length;j++){
                if(pieInputListTemp[blockSpeciesTemp[i][j]]===undefined){
                    pieInputListTemp[blockSpeciesTemp[i][j]]=new Decimal(blockRatioTemp[i][j])
                }else{
                    pieInputListTemp[blockSpeciesTemp[i][j]]=Decimal.add(pieInputListTemp[blockSpeciesTemp[i][j]],blockRatioTemp[i][j])
                }
            }
        }
        //console.log(pieInputListTemp)
        var fishnameList=Object.keys(pieInputListTemp)
        fs.mkdirSync(`layered_data/${lang}/${blockSize}/${blocknamearray[0]}/${blocknamearray[1]}`, { recursive: true }, (err) => {
            if (err) throw err;
        });
        for(i=0;i<fishnameList.length;i++){
            var pieInputListItem={}
            pieInputListItem["name"]=fishnameList[i]
            pieInputListItem["value"]=pieInputListTemp[`${fishnameList[i]}`]/samplenumber
            pieInputList.push(pieInputListItem)
        }
        console.log("[pieLat,pieLng,sampleNum]",pieCoord)
        console.log(pieInputList)
        fs.writeFileSync(`layered_data/${lang}/${blockSize}/${blocknamearray[0]}/${blocknamearray[1]}/pieCoord.json`, JSON.stringify(pieCoord, null, 2), (err) =>{
            if (err) throw err;
            console.log('Data written to file');
        });
        fs.writeFileSync(`layered_data/${lang}/${blockSize}/${blocknamearray[0]}/${blocknamearray[1]}/fishAndRatio.json`, JSON.stringify(pieInputList, null, 2), (err) =>{
            if (err) throw err;
            console.log('Data written to file');
        });
    }


}





function removeEmptyLastItem(arr) {
    if (arr.length > 0 && arr[arr.length - 1] === '') {
      arr.pop();
    }
}