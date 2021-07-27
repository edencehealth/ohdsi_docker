#!/usr/bin/Rscript
# forked from: https://raw.githubusercontent.com/OHDSI/Achilles/fc09632dc7067bb79dc54f3099370a4bb852c485/docker-run

# WARNING: this script relies on defaults set by entrypoint.sh

message("Beginning Achilles Processes...")

# Load Achilles and httr.
library(Achilles)
library(httr)

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

# Default values are defined in the entrypoint
env <- list()
env[names(Sys.getenv())] <- Sys.getenv()

env$ACH_DQD_DB_PORT <- as.numeric(env$ACH_DQD_DB_PORT)
env$ACHILLES_NUM_THREADS <- as.numeric(env$ACHILLES_NUM_THREADS)

as_bool <- function(x) as.logical(as.numeric(x))
env$ACHILLES_ENABLE_HEEL <- as_bool(env$ACHILLES_ENABLE_HEEL)
env$ACHILLES_ENABLE_HEEL_ONLY <- as_bool(env$ACHILLES_ENABLE_HEEL_ONLY)
env$ACHILLES_ENABLE_JSON_COMPRESS <- as_bool(env$ACHILLES_ENABLE_JSON_COMPRESS)
env$ACHILLES_ENABLE_JSON_EXPORT <- as_bool(env$ACHILLES_ENABLE_JSON_EXPORT)
env$ACHILLES_ENABLE_OPTIMIZE_ATLAS_CACHE <- as_bool(env$ACHILLES_ENABLE_OPTIMIZE_ATLAS_CACHE)

# Create name to tag results and output path from ACH_DQD_SOURCE_NAME and time
current_datetime <- strftime(Sys.time(), format = "%Y-%m-%dT%H.%M.%S")
output_path <- paste(
  env$ACHILLES_OUTPUT_BASE,
  env$ACH_DQD_SOURCE_NAME,
  current_datetime,
  sep = "/"
)
dir.create(output_path, showWarnings = FALSE, recursive = TRUE, mode = "0755")

# Set env datetime for other processes
ret <- Sys.setenv(TIMESTAMP_RUN = current_datetime)

if (!(env$ACH_DQD_DB_DBMS %in% valid_dbms)) {
  stop("Cannot proceed with invalid dbms: ", env$ACH_DQD_DB_DBMS)
}

if (env$ACH_DQD_DB_DBMS %in% name_concat_dbms) {
  # Some connection packages need the database on the server argument.
  # see ?createConnectionDetails after loading library(Achilles)
  server <- paste(env$ACH_DQD_DB_HOSTNAME, env$ACH_DQD_DB_NAME, sep = "/")
} else {
  server <- env$ACH_DQD_DB_HOSTNAME
}

# Create connection details using DatabaseConnector utility.
connection_details <- createConnectionDetails(
  dbms = env$ACH_DQD_DB_DBMS,
  user = env$ACH_DQD_DB_USERNAME,
  password = env$ACH_DQD_DB_PASSWORD,
  server = server,
  port = env$ACH_DQD_DB_PORT,
  pathToDriver = env$DB_DRIVER_PATH
)

if (env$ACHILLES_ENABLE_HEEL_ONLY) {
  achillesHeel(
    connection_details,
    cdmDatabaseSchema = env$ACH_DQD_CDM_SCHEMA,
    resultsDatabaseSchema = env$ACH_DQD_RES_SCHEMA,
    vocabDatabaseSchema = env$ACH_DQD_VOCAB_SCHEMA,
    cdmVersion = env$ACH_DQD_CDM_VERSION,
    numThreads = env$ACHILLES_NUM_THREADS
  )
  stop("exiting in ACHILLES_ENABLE_HEEL_ONLY mode")
}

achilles(
  connection_details,
  cdmDatabaseSchema = env$ACH_DQD_CDM_SCHEMA,
  resultsDatabaseSchema = env$ACH_DQD_RES_SCHEMA,
  vocabDatabaseSchema = env$ACH_DQD_VOCAB_SCHEMA,
  sourceName = env$ACH_DQD_SOURCE_NAME,
  cdmVersion = env$ACH_DQD_CDM_VERSION,
  createIndices = !(env$ACH_DQD_DB_DBMS %in% no_index_dbms),
  numThreads = env$ACHILLES_NUM_THREADS,
  runHeel = env$ACHILLES_ENABLE_HEEL,
  optimizeAtlasCache = env$ACHILLES_ENABLE_OPTIMIZE_ATLAS_CACHE
)

if (env$ACHILLES_ENABLE_JSON_EXPORT) {
  # Export Achilles results to output path in JSON format.
  exportToJson(
    connection_details,
    cdmDatabaseSchema = env$ACH_DQD_CDM_SCHEMA,
    resultsDatabaseSchema = env$ACH_DQD_RES_SCHEMA,
    vocabDatabaseSchema = env$ACH_DQD_VOCAB_SCHEMA,
    outputPath = output_path,
    compressIntoOneFile = env$ACHILLES_ENABLE_JSON_COMPRESS
  )
}
