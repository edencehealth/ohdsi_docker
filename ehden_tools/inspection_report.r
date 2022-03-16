#!/usr/bin/Rscript

message("Launching Inspection Report Processes...")

library(CdmInspection)
library(httr)

# Optional: specify where the temporary files (used by the ff package) will be created:
fftempdir <- if (Sys.getenv("FFTEMP_DIR") == "") "~/fftemp" else Sys.getenv("FFTEMP_DIR")
options(fftempdir = fftempdir)

valid_dbms <- list(
  "bigquery",
  "netezza",
  "oracle",
  "pdw",
  "postgresql",
  "redshift",
  "sql server",
  "sqlite"
)

## these dbms require the database name to be appended to the hostname
name_concat_dbms <- list(
  "netezza",
  "oracle",
  "postgresql",
  "redshift"
)

no_index_dbms <- list(
  "netezza",
  "redshift"
)

# Grab environment variables
env <- list()
env[names(Sys.getenv())] <- Sys.getenv()

env$ACH_DQD_DB_PORT <- as.numeric(env$ACH_DQD_DB_PORT)
env$INS_REP_CUTOFF <- as.numeric(env$INS_REP_CUTOFF)
as_bool <- function(x) as.logical(as.numeric(x))
env$INS_REP_VERBOSE <- as_bool(env$INS_REP_VERBOSE)

if (!(env$ACH_DQD_DB_DBMS %in% valid_dbms)) {
  stop("Cannot proceed with invalid dbms: ", env$ACH_DQD_DB_DBMS)
}

if (env$ACH_DQD_DB_DBMS %in% name_concat_dbms) {
  server <- paste(env$ACH_DQD_DB_HOSTNAME, env$ACH_DQD_DB_NAME, sep = "/")
} else {
  server <- env$ACH_DQD_DB_HOSTNAME
}

current_datetime <- strftime(Sys.time(), format = "%Y-%m-%dT%H.%M.%S")
output_path <- paste(
  "/output",
  env$INS_REP_OUTPUT_BASE,
  "/",
  env$INS_REP_DB_ID,
  "/",
  current_datetime,
  sep = ""
)
dir.create(output_path, showWarnings = FALSE, recursive = TRUE, mode = "0755")

outputFolder <- output_path
# *******************************************************
# SECTION 3: Run the package
# *******************************************************

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = env$ACH_DQD_DB_DBMS,
                                                                user = env$ACH_DQD_DB_USERNAME,
                                                                password = env$ACH_DQD_DB_PASSWORD,
                                                                server = server,
                                                                port = env$ACH_DQD_DB_PORT,
                                                                pathToDriver = env$DB_DRIVER_PATH)

results<-cdmInspection(connectionDetails,
                cdmDatabaseSchema = env$ACH_DQD_CDM_SCHEMA,
                resultsDatabaseSchema = env$ACH_DQD_RES_SCHEMA,
                vocabDatabaseSchema = env$ACH_DQD_VOCAB_SCHEMA,
                oracleTempSchema = oracleTempSchema,
                databaseName = env$INS_REP_DB_NAME,
                runVocabularyChecks = TRUE,
                runDataTablesChecks = TRUE,
                runPerformanceChecks = TRUE,
                runWebAPIChecks = TRUE,
                smallCellCount = env$INS_REP_CUTOFF,
                baseUrl = env$INS_REP_BASE_URL,
                sqlOnly = FALSE,
                outputFolder = outputFolder,
                verboseMode = TRUE)

generateResultsDocument(results,
                        outputFolder,
                        authors=env$INS_REP_AUTHOR,
                        databaseDescription = env$INS_REP_DESCRIPTION,
                        databaseName = env$INS_REP_DB_NAME,
                        databaseId = env$INS_REP_DB_ID,
                        smallCellCount = env$INS_REP_CUTOFF)
