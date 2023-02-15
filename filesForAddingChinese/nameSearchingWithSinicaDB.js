const request = require('request')
const {
  JSDOM
} = require('jsdom')
var fs = require("fs");

const args = process.argv.slice(2)
var speciesLatinName=args.join(' ')
var genusPart=args[0]
var speciesPart=args[1]
var speciesLatinNameForLink=genusPart+"+"+speciesPart
//console.log(speciesLatinNameForLink)
searchingSinica(speciesLatinNameForLink,speciesLatinName); 

function searchingSinica(speciesLatinNameForLink,speciesLatinName){
  request(`https://fishdb.sinica.edu.tw/chi/chinesequer2.php?hideme=&T1=${speciesLatinNameForLink}&T1_new_value=true`, (e, response, body) => {
    //if (e) {
      //console.error(e)
    //}
    try {
      const dom = new JSDOM(body)
      const latinName = dom.window.document.querySelector("#main > center > form > table:nth-child(9) > tbody > tr:nth-child(2) > td:nth-child(4) > font > i").textContent
      const zhName = dom.window.document.querySelector("#main > center > form > table:nth-child(9) > tbody > tr:nth-child(2) > td:nth-child(6) > font").textContent.trim()
      if(zhName!==null){
        if(latinName===speciesLatinName){
          console.log(`${zhName}`+":"+`${speciesLatinName}`);
        } 
      }
    } catch (e) {
      //console.error(e)
    }
  })
}