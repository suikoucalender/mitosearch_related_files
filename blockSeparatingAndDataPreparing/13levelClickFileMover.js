const fs = require('fs');
const path = require('path');
const args = process.argv.slice(2)
let lang=args[0]

const moveFiles = (sourceDir, targetDir) => {
    fs.readdir(sourceDir, (err, files) => {
        if (err) {
            console.error('Error reading source directory:', err);
            return;
        }

        files.forEach(file => {
            const sourcePath = path.join(sourceDir, file);
            const targetPath = path.join(targetDir, file);

            fs.rename(sourcePath, targetPath, err => {
                if (err) {
                    console.error('Error moving file:', file, err);
                } else {
                    console.log('Moved file:', file);
                }
            });
        });
    });
};

let groupedList=fs.readFileSync(`layered_data/${lang}/special/aGroupedDataList.json`)
groupedList=JSON.parse(groupedList)
let keys=Object.keys(groupedList)
keys.forEach(key=>{
    let keyParts=key.split(",")
    let sampleOriginalPath = `layered_data/${lang}/special/${keyParts[0]}/${keyParts[1]}`
    moveFiles(`${sampleOriginalPath}`,`layered_data/${lang}/special/`)
})