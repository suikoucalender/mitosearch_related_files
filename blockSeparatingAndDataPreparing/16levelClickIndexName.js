const fs = require('fs');
const path = require('path');
const args = process.argv.slice(2)
let lang=args[0]


const folderPath = `layered_data/${lang}/special/index`;


fs.readdir(folderPath, (err, files) => {
    if (err) {
        console.error('Error reading the directory', err);
        return;
    }

    let fileNames = files
        .filter(file => fs.statSync(path.join(folderPath, file)).isFile())
        .map(file => path.parse(file).name);

    let json = JSON.stringify(fileNames);

    fs.writeFile(`layered_data/${lang}/special/aIndexNames.json`, json, 'utf8', (err) => {
        if (err) {
            console.error('Error writing JSON to file', err);
        } else {
            console.log('index name file saved');
        }
    });
});
