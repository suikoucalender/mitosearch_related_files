const fs = require('fs');
const path = require('path');
const args = process.argv.slice(2)
let lang=args[0]
//to recursively read directory contents
function readDirectory(dir, fileList = []) {
    const files = fs.readdirSync(dir);

    files.forEach((file) => {
        const filePath = path.join(dir, file);
        if (fs.statSync(filePath).isDirectory()) {
            fileList = readDirectory(filePath, fileList); // Recurse into subdirectory
        } else {
            if (filePath.indexOf(".DS_Store")==-1&&filePath.indexOf("locationlist")==-1){
                fileList.push(filePath); // Add file path to list
            }   
        }
    });

    return fileList;
}

//to create an index and save it as JSON
function createIndex(rootDir) {
    const index = readDirectory(rootDir);
    const indexJSON = JSON.stringify(index, null, 2);
    //fs.writeFileSync('fileIndex.json', indexJSON);
    return index
}

let filePaths
filePaths=createIndex(`layered_data/${lang}/special`);

let groupedPaths = {};

filePaths.forEach(filePath => {
    let parts = filePath.split('/');
    let lat = parts[3];
    let lon = parts[4];
    let fileName = parts[parts.length - 1];
    let key = `${lat},${lon}`;

    if (!groupedPaths[key]) {
        groupedPaths[key] = [];
    }
    groupedPaths[key].push(fileName);
});

let groupedPathsJSON=JSON.stringify(groupedPaths,null,2);
fs.writeFileSync(`layered_data/${lang}/special/aGroupedDataList.json`,groupedPathsJSON)

