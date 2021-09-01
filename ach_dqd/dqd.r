#!/usr/bin/Rscript

# WARNING: this script relies on defaults set by entrypoint.sh

# WARNING: Valid dbms checked in achilles.r, not re-checked here.

message("Beginning DQD Processes...")
# Load Achilles and httr.
library(Achilles)
library(httr)

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

# Default values are defined in the entrypoint
env <- list()
env[names(Sys.getenv())] <- Sys.getenv()

env$ACH_DQD_DB_PORT <- as.numeric(env$ACH_DQD_DB_PORT)
env$DQD_NUM_THREADS <- as.numeric(env$DQD_NUM_THREADS)

as_bool <- function(x) as.logical(as.numeric(x))
env$DQD_ENABLE_JSON_TO_TABLE <- as_bool(env$DQD_ENABLE_JSON_TO_TABLE)
env$DQD_SQL_ONLY <- as_bool(env$DQD_SQL_ONLY)
env$DQD_VERBOSE_MODE <- as_bool(env$DQD_VERBOSE_MODE)
env$DQD_WRITE_TO_TABLE <- as_bool(env$DQD_WRITE_TO_TABLE)

output_path <- paste(
  env$DQD_OUTPUT_BASE,
  env$ACH_DQD_SOURCE_NAME,
  env$TIMESTAMP_RUN,
  sep = "/"
)

# Assign values to special env variables
if (env$ACH_DQD_DB_DBMS %in% name_concat_dbms) {
  # Some connection packages need the database on the server argument.
  # see ?createConnectionDetails after loading library(Achilles)
  server <- paste(env$ACH_DQD_DB_HOSTNAME, env$ACH_DQD_DB_NAME, sep = "/")
} else {
  server <- env$ACH_DQD_DB_HOSTNAME
}

if (env$DQD_CHECK_LEVELS != "0") {
  env$DQD_CHECK_LEVELS <- toupper(unlist(strsplit(env$DQD_CHECK_LEVELS, "_")))
} else {
  stop("Cannot proceed with no check levels defined")
}

if (env$DQD_CHECK_NAMES != "0") {
  env$DQD_CHECK_NAMES <- toupper(unlist(strsplit(env$DQD_CHECK_NAMES, "_")))
} else {
  env$DQD_CHECK_NAMES <- c()
}

if (env$DQD_TABLES_TO_EXCLUDE != "0") {
  env$DQD_TABLES_TO_EXCLUDE <- toupper(unlist(strsplit(env$DQD_TABLES_TO_EXCLUDE, "_")))
} else {
  env$DQD_TABLES_TO_EXCLUDE <- c()
}

# Create connection details using DatabaseConnector utility.
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = env$ACH_DQD_DB_DBMS,
  user = env$ACH_DQD_DB_USERNAME,
  password = env$ACH_DQD_DB_PASSWORD,
  server = server,
  port = env$ACH_DQD_DB_PORT,
  pathToDriver = env$DB_DRIVER_PATH
)

output_file <- paste("DQD_Results", env$TIMESTAMP_RUN, ".json", sep = "")

DataQualityDashboard::executeDqChecks(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = env$ACH_DQD_CDM_SCHEMA,
  resultsDatabaseSchema = env$ACH_DQD_RES_SCHEMA,
  cdmSourceName = env$ACH_DQD_SOURCE_NAME,
  numThreads = env$DQD_NUM_THREADS,
  sqlOnly = env$DQD_SQL_ONLY,
  outputFolder = output_path,
  outputFile = output_file,
  verboseMode = env$DQD_VERBOSE_MODE,
  writeToTable = env$DQD_WRITE_TO_TABLE,
  checkLevels = env$DQD_CHECK_LEVELS,
  tablesToExclude = env$DQD_TABLES_TO_EXCLUDE,
  checkNames = env$DQD_CHECK_NAMES
)

#Save output filename for use by DQD Viz
ret <- Sys.setenv(DQD_JSON_FILE_NAME = output_file)

if (env$DQD_ENABLE_JSON_TO_TABLE) {
  # Export Achilles results to output path in JSON format.
  DataQualityDashboard::writeJsonResultsToTable(
    connectionDetails = connection_details,
    resultsDatabaseSchema = env$ACH_DQD_RES_SCHEMA,
    # WARNING Json saved in same directory as other ACH/DQD output.
    jsonFilePath = output_path
  )
}
