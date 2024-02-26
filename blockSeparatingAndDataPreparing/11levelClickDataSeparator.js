const fs = require('fs');
const Decimal = require('decimal.js')
const args = process.argv.slice(2)
let lang=args[0]
// read lat-long-date.txt file
var locationInfo;
locationInfo=fs.readFileSync("lat-long-date.txt",'utf8');
locationInfo=locationInfo.split('\n');
removeEmptyLastItem(locationInfo);
for(var i=0;i<locationInfo.length;i++){
    locationInfo[i]=locationInfo[i].split('\t');
    locationInfo[i][1]=locationInfo[i][1].split(' ') 
}

//read mapwater.result.txt file
var aquaDataTemp=fs.readFileSync("mapwater.result.txt",'utf8');
aquaDataTemp=aquaDataTemp.split('\n')
var aquaData={}
removeEmptyLastItem(aquaDataTemp);
for(var i=0;i<aquaDataTemp.length;i++){
    aquaDataTemp[i]=aquaDataTemp[i].split('\t');
    aquaData[aquaDataTemp[i][0]]=`${aquaDataTemp[i][1]}`;
}
//console.log(aquaData)

//Delete missing or abnormal or non-water-area latitude and longitude data
for (let i = locationInfo.length - 1; i >= 0; i--) {
    //console.log("key",`${locationInfo[i][0]}`)
    if (locationInfo[i][1][0]==="" || locationInfo[i][1].length!==4 || isNaN(locationInfo[i][1][0]) || aquaData[`${locationInfo[i][0]}`]===`0`) {
        //console.log("removed",aquaData[`${locationInfo[i][0]}`])
        locationInfo.splice(i, 1);
    }///else{
        //console.log("saved",aquaData[`${locationInfo[i][0]}`])
    //}
}

//Convert latitude and longitude to digital format, Set the longitude west, latitude south to negative values for easier calculations and comparisons.
for(var i=0;i<locationInfo.length;i++){
    locationInfo[i][1][0]=parseFloat(locationInfo[i][1][0])
    if(locationInfo[i][1][1]==="S"){
        locationInfo[i][1][0]=-locationInfo[i][1][0]
    }
    locationInfo[i][1][2]=parseFloat(locationInfo[i][1][2])
    if(locationInfo[i][1][3]==="W"){
        locationInfo[i][1][2]=-locationInfo[i][1][2]
    }
}

var data=[]
for(var i=0;i<locationInfo.length;i++){
    var datatemp={}
    var inputFileID=locationInfo[i][0]
    var inputFileName=inputFileID+".input"
    var inputFilePath=`db_fish_${lang}/${inputFileName}`
    //var species=[]
    var tempSpecies
    if (!fs.existsSync(inputFilePath)) {
        //console.log(`${inputFileID}.input does not exist. Skipping...`);
        continue; // Skip to next iteration if file does not exist
    }

    datatemp["ID"]=inputFileID;
    datatemp["lat"]=locationInfo[i][1][0];
    datatemp["long"]=locationInfo[i][1][2];
    datatemp["time"]=locationInfo[i][2];
    //read files
    tempSpecies=fs.readFileSync(inputFilePath,'utf8');
    //convert to array
    tempSpecies=tempSpecies.split('\n');
    //remove the first item and empty last item
    tempSpecies.splice(0, 1);
    removeEmptyLastItem(tempSpecies);
    //console.log(tempSpecies)

    //console.log("---------")
    //Organize into associative arrays
    var speciesTemp=[]
    for(var j=0;j<tempSpecies.length;j++){
        var species={}
        tempSpecies[j]=tempSpecies[j].split('\t');
        //console.log(tempSpecies[j])
        species["name"]=tempSpecies[j][0];
        species["value"]=parseFloat(tempSpecies[j][1]);
        //console.log(species)
        speciesTemp.push(species)
        //console.log(speciesTemp)
        //console.log(datatemp)
    }
    datatemp["species"]=speciesTemp;
        //datatemp["species"].push(species)
    data.push(datatemp)
}

//console.log(data)


let blocknamelist = [];

for(i=0;i<data.length;i++){
    var latTemp=data[i]["lat"]
    var longTemp=data[i]["long"]
    var idTemp=data[i]["ID"]
    var fileTemp=data[i]
    writeFileOrDirectory(latTemp,longTemp,idTemp,fileTemp)
}
//blocknamelist=[...new Set(blocknamelist)]
//fs.writeFileSync(`new/special/locationlist.json`, JSON.stringify(blocknamelist, null, 2), { recursive: true });

function writeFileOrDirectory(latTemp,longTemp,idTemp,fileTemp) {
    let filePath = `layered_data/${lang}/special/${latTemp}/${longTemp}`;
 
    try {
        // check if the path exist
        fs.access(filePath, fs.constants.F_OK);
    } catch (err) {
        // if there is not, make the path
        fs.mkdirSync(filePath, { recursive: true });
        //blocknamelist.push([latTemp,longTemp])
    }

    // write the file
    fs.writeFileSync(`${filePath}/${idTemp}.json`, JSON.stringify(fileTemp, null, 2), { recursive: true });
}


function removeEmptyLastItem(arr) {
    if (arr.length > 0 && arr[arr.length - 1] === '') {
      arr.pop();
    }
}

