# OHDSI EHDEN TOOLS

## Get Started

### TO BUILD

- Execute `docker-compose build` in the project directory. Adding the argument `image:` in the `docker-compose.yml` file below `build:` will allow you to update the name/tag of the image

- Note that the files `network_file_*` and `style_sheet_*` are pre-pulled from their network locations and copied (see Dockerfile near-end) to a new `offline` directory in the DataQualityDashboard shiny app source code. The `index.html` file is modified to reference these new offline files and properly render the json viewer in network isolation.
- All packages and dependencies are installed for Achilles, DQD, and CdmInspection. **NOTE** that Achilles Heel has been removed from the Achilles repository as of Dec 2021, so this version of Achilles does not run Heel (env variables related to Heel are also now removed). This is not a problem for atlas because DQD fills the tables that Heel would originally populate.
- A word of caution: the build process from scratch takes 30+ minutes depending on your machine, so modify the Dockerfile with care.

### TO RUN

- There are quite a few environment variables that can be modified for the various services (see docker-compose.override.yml); most can be left as their defaults. 
- The critical variables for executing the various OHDSI Tools contain the suffix: `_RUN`, and there are 5 of them:

	- `ACHILLES_RUN`
	- `DQD_RUN`
	- `DQD_VIZ_RUN`
	- `INS_REP_RUN`
	- `CAT_ENT_RUN`

Depending on the values in these four boolean (1 or 0) variables, you can launch the service in different run modes:

- **RUN MODE 1**: Achilles, DQD & Visualize
	- `ACHILLES_RUN=1`
	- `DQD_RUN=1`
	- `DQD_VIZ_RUN=1`
	- `INS_REP_RUN=1 or 0` 
	- `CAT_ENT_RUN=1 or 0` 
	- Launches all QC/AT processes, ending with the dashboard viewer of the .json file at localhost:5641. **Inspection report & Catalogue Entry are not executed.**

- **RUN MODE 2**: Achilles Only
	- `ACHILLES_RUN=1`
	- `DQD_RUN=0`
	- `DQD_VIZ_RUN=0`
	- `INS_REP_RUN=1 or 0` 
	- `CAT_ENT_RUN=1 or 0` 
	- Launches only Achilles and exits. Achilles logs are populated, as are tables in the results schema. **Inspection report & Catalogue Entry are not executed.**

- **RUN MODE 3**: DQD Only
	- `ACHILLES_RUN=0`
	- `DQD_RUN=1`
	- `DQD_VIZ_RUN=0`
	- `INS_REP_RUN=1 or 0` 
	- `CAT_ENT_RUN=1 or 0` 
	- Launches only DQD and exits. Note that Achilles MUST be executed before this run mode, or it will fail due to dependencies of DQD on Achilles. **Inspection report & Catalogue Entry are not executed.**

- **RUN MODE 4**: DQD Visualize ONLY
	- `ACHILLES_RUN=0`
	- `DQD_RUN=0`
	- `DQD_VIZ_RUN=1`
	- `INS_REP_RUN=1 or 0` 
	- `CAT_ENT_RUN=1 or 0` 
	- Launches the DQD shiny app, viewing the file DQD_Results.json in the local directory that you've mounted to `/output`. NOTE that the variable `DQD_VIZ_JSON_PATH` needs to be changed from 0 to `/output`. **Inspection report & Catalogue Entry are not executed.**

- **RUN MODE 5**: CDM Inspection Report
	- `ACHILLES_RUN=0`
	- `DQD_RUN=0`
	- `DQD_VIZ_RUN=0`
	- `INS_REP_RUN=1` 
	- `CAT_ENT_RUN=1 or 0`
	- Launches the inspection report and produces a word document with various plots and tables that you can find in your locally mounted directory.  NOTE - Atlas/Webapi must be up and running before launching the inspection report. **Catalogue Entry is not executed.**

- **RUN MODE 6**: Catalogue Entry
	- `ACHILLES_RUN=0`
	- `DQD_RUN=0`
	- `DQD_VIZ_RUN=0`
	- `INS_REP_RUN=0` 
	- `CAT_ENT_RUN=1` 
	- Launches the catalogue entry creation process and produces a csv document with counts of various concepts and additional metadata that you can find in your locally mounted directory. **Inspection report is not executed.**

- The service can be executed with the command `docker-compose run --rm --service-ports ohdsi_ehden_tools`


Good Luck!
