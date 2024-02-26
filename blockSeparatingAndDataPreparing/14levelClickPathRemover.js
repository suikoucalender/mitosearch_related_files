const fs = require('fs');
const path = require('path');
const args = process.argv.slice(2)
let lang=args[0]


let groupedList=fs.readFileSync(`layered_data/${lang}/special/aGroupedDataList.json`)
groupedList=JSON.parse(groupedList)
let keys=Object.keys(groupedList)

keys.forEach(key=>{
    let keyParts=key.split(",")
    let sampleOriginalPath = `layered_data/${lang}/special/${keyParts[0]}`
    deleteFolder(sampleOriginalPath)
    //console.log(sampleOriginalPath)
})


function deleteFolder(folderPath) {
    try {
        fs.rmSync(folderPath, { recursive: true });
        console.log(`Folder deleted: ${folderPath}`);
    } catch (err) {
        console.error(`Error deleting folder: ${err}`);
    }
}
