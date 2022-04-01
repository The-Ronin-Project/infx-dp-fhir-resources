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

The mapping between MDA Resources and Ronin R4/mCODE is detailed in the [FHIR Resources](https://docs.google.com/spreadsheets/d/1qSqmaAK_GaDUUZACUQ6TI5Q9qvQ2BwvQ_KRjl10OoU0/edit?ts=60be5536#gid=0) sheet.

Introduction to FHIR profiling:
1. [FHIR Profiling: Overview and Information](https://www.youtube.com/watch?v=dku3lqIYEls)

# Build Process
To build the profiles, use the following commands:
```
$ gem install jekyll
$ git clone git@github.com:projectronin/infx-dp-fhir-resources.git
$ cd infx-dp-fhir-resources
$ ./_updatePublisher.sh
$ ./_genonce.sh -no-sushi
$ open ./output/index.html
```
Implementation guide artifacts are in `output` directory.

If you want to obtain an ndjson.gz to test with Aidbox locally use the following command:
```
$ ./_genSamples.sh -d test -v -a http://localhost:8888
```
**Note** The URL http://localhost:8888 is for local only, do not try to upload the bundle.json to QA Aidbox.

The resultant test.ndjson.gz can be uploaded to local Aidbox for testing.

# Custom Resources
Ronin defines some custom resources that must be registered with Aidbox before being able to access it via the Aidbox APIs or Notebooks
The cutom resources' schemas (json files) are defined in the custom/schema folder.

To register custom resources, import this Notebook into your local Aidbox dashboard:
https://aidbox.app/ExportedNotebook/c95f3d44-6c20-492b-8027-3365969d7cb7  
  
  
**NB DO NOT PRESS PUBLISH ON ANY NOTEBOOK** - it will make it public to the world.

Follow the Notebook instructions to register the custom resource before usage.

# Example Profile Instances
The diagram below is a bundle image of the generated instances from of oncology examples resources.
The visualization was done with [Bundle Visualizer](http://clinfhir.com/bundleVisualizer.html) by replacing *ronin* with *xyz* and *MDA* with *abc*

![Ronin Oncology Example](./input/images/RoninOncologyExample.png?raw=true "Ronin Oncology Example")

# TODO
- [ ] Add github command to push to Nexus