const { addAbortListener } = require('events');
const Decimal = require('./decimal.js');
const args = process.argv.slice(2)
const fs = require('fs');
const path = require('path');
const { spec } = require('node:test/reporters');

const locationPath = args[0]; //lat-long-data.txt
const imputFolderPath = args[1]; //db_fish_[language]
//let blockSize = new Decimal(args[2]); //ratioAndBlock={"2":45,"3":30,"4":15,"5":5,"6":3,"7":2,"8":1,"9":0.5,"10":0.2,"11":0.1,"12":0.05,"13":0.05,"14":0.02,"15":0.02,"16":0.02,"17":0.01,"18":"special"}
let lang = imputFolderPath.slice(-2); //最後の2文字を切り出す

// read lat-long-date.txt file
let locationInfo = fs.readFileSync(locationPath, 'utf8');
let locationInfoLines = locationInfo.split('\n');
removeEmptyLastItem(locationInfoLines);
let locationInfoItems = [];
for (let i = 0; i < locationInfoLines.length; i++) {
    let templocationInfoItem = locationInfoLines[i].split('\t');
    let tempLatLong = templocationInfoItem[1].split(' ')
    if (tempLatLong[0] !== "" && tempLatLong.length === 4 && !isNaN(tempLatLong[0])) {
        //経度緯度が記述されていれば追加
        locationInfoItems.push(templocationInfoItem);
    }
}

let blockSizes = { "2": "45", "3": "30", "4": "15", "5": "5", "6": "3", "7": "2", "8": "1", "9": "0.5", "10": "0.2", "11": "0.1", "12": "0.05", "14": "0.02", "17": "0.01" }
for (const blockSizeKey of Object.keys(blockSizes)) {
    const blockSize = new Decimal(blockSizes[blockSizeKey])
    console.log("blockSize: ", blockSize)
    //ブロックごとにどのSRR IDが来るかを分別
    //prepare block information
    let blockInfo = {}
    let data = {}
    //Convert latitude and longitude to digital format
    for (let i = 0; i < locationInfoItems.length; i++) {
        let tempLatLong = locationInfoItems[i][1].split(' ')
        let tempLat = new Decimal(tempLatLong[0])
        let tempLong = new Decimal(tempLatLong[2])
        if (tempLatLong[1] === "S") { tempLat = tempLat.div(-1) }
        if (tempLatLong[3] === "W") { tempLong = tempLong.div(-1) }
        let blocklattemp = Decimal.floor(tempLat.div(blockSize)).mul(blockSize)
        let blocklongtemp = Decimal.floor(tempLong.div(blockSize)).mul(blockSize)
        let key = `${blocklattemp},${blocklongtemp}`

        // reading .input files and Integrating location Info
        let inputFileID = locationInfoItems[i][0] //SRR24416895など
        let inputFileName = inputFileID + ".input"
        let inputFilePath = `${imputFolderPath}/${inputFileName}`
        let species = {}
        let tempSpecies
        if (!fs.existsSync(inputFilePath)) {
            //console.log(`${inputFileID}.input does not exist. Skipping...`);
            continue; // Skip to next iteration if file does not exist
        }
        //read files
        tempSpecies = fs.readFileSync(inputFilePath, 'utf8');
        //convert to array
        let tempSpeciesLines = tempSpecies.split('\n');
        //remove the first item and empty last item
        tempSpeciesLines.splice(0, 1);
        removeEmptyLastItem(tempSpeciesLines);
        //Organize into associative arrays
        for (let j = 0; j < tempSpeciesLines.length; j++) {
            let tempSpeciesItems = tempSpeciesLines[j].split('\t');
            //console.log(tempSpeciesItems)
            species[tempSpeciesItems[0]] = new Decimal(tempSpeciesItems[1]);
        }
        let datatemp = { time: locationInfoItems[i][2], lat: tempLat, long: tempLong, species: species }
        data[inputFileID] = datatemp

        if (!(key in blockInfo)) {
            blockInfo[key] = [inputFileID];
        } else {
            blockInfo[key].push(inputFileID);
        }
    }
    //console.log(blockInfo)//looks like {`blocklat,blocklng`:fileName}
    let blockname = Object.keys(blockInfo)

    //console.log(data)

    for (let x = 0; x < blockname.length; x++) {//loop for each block
        //円グラフを作成
        //follow the block information, prepare pie data
        let blocknamearray = blockname[x].split(',')
        let samplenumber = blockInfo[blockname[x]].length
        let sumLat = new Decimal(0)
        let sumLong = new Decimal(0)
        let blockSpecies = {}
        console.log("--------------------------(" + blocknamearray + ")--------------------------")
        for (let s = 0; s < samplenumber; s++) {//loop for each file
            let filename = blockInfo[blockname[x]][s]
            let fileSpeciesData = data[filename] //lat, long, time, species{}
            //record pie location
            sumLat = Decimal.add(sumLat, fileSpeciesData.lat)
            sumLong = Decimal.add(sumLong, fileSpeciesData.long)
            let fileSpeciesName = Object.keys(fileSpeciesData.species)
            for (let y = 0; y < fileSpeciesName.length; y++) {//loop for each species
                if (!(fileSpeciesName[y] in blockSpecies)) {
                    blockSpecies[fileSpeciesName[y]] = parseFloat(fileSpeciesData.species[fileSpeciesName[y]])
                } else {
                    blockSpecies[fileSpeciesName[y]] += parseFloat(fileSpeciesData.species[fileSpeciesName[y]])
                }
                //console.log(parseFloat(fileSpeciesData.species[fileSpeciesName[y]]), blockSpecies[fileSpeciesName[y]])
            }
        }
        let averageLat = Decimal.div(sumLat, samplenumber)//pie chart location
        let averageLong = Decimal.div(sumLong, samplenumber)

        let pieInputList = []
        let blockSpeciesKeys = Object.keys(blockSpecies)
        for (let s = 0; s < blockSpeciesKeys.length; s++) {
            pieInputList.push({ name: blockSpeciesKeys[s], value: blockSpecies[blockSpeciesKeys[s]] / samplenumber })
        }

        //calcutate the ratio of each species in each block
        if (blockSpeciesKeys.length !== 0) {//some sample is in lat-lng-date.txt file, but there were no input file, remove them in this step.
            fs.mkdirSync(`layered_data/${lang}/${blockSize}/${blocknamearray[0]}/${blocknamearray[1]}`, { recursive: true }, (err) => {
                if (err) throw err;
            });
            //円グラフを描く位置とサンプル数を出力
            let pieCoord = [averageLat, averageLong, samplenumber]
            console.log("[pieLat,pieLng,sampleNum]: ", pieCoord)
            fs.writeFileSync(`layered_data/${lang}/${blockSize}/${blocknamearray[0]}/${blocknamearray[1]}/pieCoord.json`, JSON.stringify(pieCoord, null, 2), (err) => {
                if (err) throw err;
                console.log('Data written to file');
            });
            fs.writeFileSync(`layered_data/${lang}/${blockSize}/${blocknamearray[0]}/${blocknamearray[1]}/fishAndRatio.json`, JSON.stringify(pieInputList, null, 2), (err) => {
                if (err) throw err;
                console.log('Data written to file');
            });
        }

        //月ごとにデータを集約したファイルを作成
        let MonthSamples = {}
        for (let s = 0; s < samplenumber; s++) {//loop for each file
            let filename = blockInfo[blockname[x]][s]
            let fileData = data[filename] //lat, long, time, species{}
            const regex = /^[12][0-9]{3}-[0-9]{2}/; //年月が1xxx-xx, 2xxx-xxを対象
            const isMatch = regex.test(fileData.time);
            if(isMatch){
                const Month = fileData.time.slice(5,7) //月を抜き出す
                if (!(Month in MonthSamples)) {
                    MonthSamples[Month] = [filename];
                } else {
                    MonthSamples[Month].push(filename);
                }
            }else{
                console.log("Date is missing: ", filename)
            }
        }
        //月ごとに生物種を集計
        let MonthWholeData = []
        for (const month in MonthSamples) {
            let monthSpeciesData = {}
            let sampleNumberInMonth = MonthSamples[month].length
            for (const filename of MonthSamples[month]) {
                const monthSampleData = data[filename].species;
                for(const specname in monthSampleData){
                    if(!(specname in monthSpeciesData)){
                        monthSpeciesData[specname] = parseFloat(monthSampleData[specname])
                    }else{
                        monthSpeciesData[specname] += parseFloat(monthSampleData[specname])
                    }
                }
            }
            let monthInputList = []
            for(const specname in monthSpeciesData){
                monthInputList.push({name: specname, value: monthSpeciesData[specname] / sampleNumberInMonth})
            }
            console.log("### month, sampleNumberInMonth: ", month, sampleNumberInMonth)
            MonthWholeData.push({month: month, num: sampleNumberInMonth, data: monthInputList})
        }
        //月ごとの種組成を出力
        if(MonthWholeData.length!=0){
            fs.writeFileSync(`layered_data/${lang}/${blockSize}/${blocknamearray[0]}/${blocknamearray[1]}/month.json`,
             JSON.stringify(MonthWholeData, null, 2), (err) => {
                if (err) throw err;
                console.log('Data written to file');
            });
        }
    }


}

function removeEmptyLastItem(arr) {
    if (arr.length > 0 && arr[arr.length - 1] === '') {
        arr.pop();
    }
}