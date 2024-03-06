const fs = require('fs');
const Decimal = require('./decimal.js')
const args = process.argv.slice(2)
let blockSize = new Decimal(args[0]);
let lang = args[1]

//read index files
let groupedList=fs.readFileSync(`layered_data/${lang}/special/aGroupedDataList.json`)
groupedList=JSON.parse(groupedList)
let keys=Object.keys(groupedList)
//console.log(keys)

let indexSave={}
keys.forEach(key => {
    console.log("key: ", key)
    let keysplit = key.split(",")
    let keylat=new Decimal(keysplit[0])
    let keylng=new Decimal(keysplit[1])
    let blocklat=getBlockStartCoord(keylat,blockSize,"lat")
    let blocklng=getBlockStartCoord(keylng,blockSize,"lng")
    let block=`${blocklat},${blocklng}`
    console.log(block)
    if((block in indexSave)===false){
        indexSave[block]=[]
    }
    let temp={}
    temp[key]=groupedList[key]
    indexSave[block].push(temp)
});
//console.log(indexSave)
//let indexSaveJSON=JSON.stringify(indexSave,null,2);
//fs.writeFileSync('new/special/aindexSave.json',indexSaveJSON)
if (fs.existsSync(`layered_data/${lang}/special/index`)===false) {
    fs.mkdirSync(`layered_data/${lang}/special/index`)
} 
//separating the index file according to the block coordinate.
let indexkeys=Object.keys(indexSave)
indexkeys.forEach(indexkey =>{
    let SaveTemp=indexSave[indexkey]
    let SaveTempJSON=JSON.stringify(SaveTemp,null,2)
    //console.log(SaveTempJSON)
    fs.writeFileSync(`layered_data/${lang}/special/index/${indexkey}.json`,SaveTempJSON)
});



function getBlockStartCoord(coordinate, blockSize, latORlng) {
    let cons
    if (latORlng==="lat"){
        cons=new Decimal(90)
    }else if(latORlng==="lng"){
        cons=new Decimal(180)
    }
    // Convert latitude and longitude into positive ranges to facilitate calculations
    let offsetFromMin = Decimal.add(coordinate,cons)
    // Calculate the number of blocks
    let blockNumber = Decimal.floor(Decimal.div(offsetFromMin, blockSize))
    // Calculates and returns the starting coordinates of the block
    return Decimal.sub(Decimal.mul(blockNumber, blockSize),cons)
}