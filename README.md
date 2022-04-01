# infx-dp-fhir-resources  
This repository contains the FHIR resources exported from `Forge` along with examples, custom artifacts, markdowns and all necessary scripts to generate an Implementation Guide (IG) and test bundles to upload to Aidbox QA or local testing.  
Github actions build the IG and deploy to [crispy-carnival](https://crispy-carnival-61996e6e.pages.github.io/), they also push the `package.tgz` file to `Nexus` (TBD)  

### Directory structure

```bash
infx-dp-fhir-resources  
├── custom  
│   ├── notes  
│   ├── resources  
│   └── schema  
└── input  
    ├── examples  
    ├── includes  
    ├── pagecontent  
    └── resources  
```

**custom** directory contains **notes**, **resources**, **schema** related to DocumentReference test examples, DetectedEdVisit examples and schema. These are used by _genSamples.sh to create `test.ndjson.gz` and the `bundle.json`  
  
**input** directory contains **examples** resources (both test and example jsons), **includes** which contains the menu.xml file for IG, **pagecontent** which contains the markdown text for the IG pages and **resources** which are the `Forge` exported resources constraining/documenting the profile.  
  
The process is to create a branch linked to a JIRA ticket e.g. `INFX-1111/modify_patient_resource`.  Export the modifications from `Forge` and copy relevant JSONs into `input/resources` and/or `input/examples`.  Check-in the resources, create a PR.  Once all tests pass and PR is approved, merge to `master` - the rest is handled by Github Actions.  Please verify that new updates are in `crispy-carnival` and `Nexus` (once implemented).  