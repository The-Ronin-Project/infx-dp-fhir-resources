// make a bundle containing all of the resources in the folder
// called from _genSamples.sh with ./temp/stage containing FHIR resources.

const fs = require('fs');

let bundleOutputFileName = "./bundle.json"
let bundle = {resourceType:'Bundle',type:'transaction',entry:[]}
var args = process.argv.slice(2);

if (args.length === 0 || args.length != 2) {
  console.log("Usage: node generate_bundle.js <path to json resources> <aidbox_url>")
  console.log("Note arguments must be in the same order.")
  console.log("If QA aidbox, aidbox_url is https://qa.project-ronin.aidbox.app/")
  console.log("If localhost aidbox, default aidbox_url is http://localhost:8888/")
  return 1;
}
//Path and aidbox_url must have "/" at the end.
console.log('Arguments: ')
console.log('\targs0: ' + args[0])
console.log('\targs1: ' + args[1])
let folderPath = args[0].replace(/\/?\s*$/, "/");
let aidbox_url = args[1].replace(/\/?\s*$/, "/");
let folder = fs.readdirSync(folderPath);

folder.forEach(file => {
  if (file.includes('ImplementationGuide')) {
    return;
  }
  let fullPath = folderPath + file;
  let resource = fs.readFileSync(fullPath);
  if (resource) {
    console.log('Adding ' + fullPath)
    let json = JSON.parse(resource);
    if (json.resourceType) {
      let entry = {};
      entry.fullUrl = aidbox_url + json.resourceType + '/' + json.id
      entry.request = {}
      entry.request.method = "PUT"
      entry.request.url = '/' + json.resourceType + '/' + json.id
      entry.resource = json;
      bundle.entry.push(entry);
    }
  }
})

fs.writeFileSync(bundleOutputFileName,JSON.stringify(bundle,null,2))
console.log('Bundle created: ' + bundleOutputFileName)
