#!/bin/sh

warn() {
  printf '%s %s\n' "$(date '+%FT%T')" "$*" >&2
}

die() {
  warn "FATAL:" "$@"
  exit 1
}

main() {
  warn "ENTRYPOINT starting; $(id)"

  #config-related variables
  export \
    ACH_DQD_CDM_SCHEMA="${ACH_DQD_CDM_SCHEMA:-public}" \
    ACH_DQD_CDM_VERSION="${ACH_DQD_CDM_VERSION:-5}" \
    ACH_DQD_DB_DBMS="${ACH_DQD_DB_DBMS:-postgresql}" \
    ACH_DQD_DB_HOSTNAME="${ACH_DQD_DB_HOSTNAME:-db}" \
    ACH_DQD_DB_NAME="${ACH_DQD_DB_NAME:-postgres}" \
    ACH_DQD_DB_PASSWORD="${ACH_DQD_DB_PASSWORD:-}" \
    ACH_DQD_DB_PORT="${ACH_DQD_DB_PORT:-5432}" \
    ACH_DQD_DB_USERNAME="${ACH_DQD_DB_USERNAME:-postgres}" \
    ACH_DQD_RES_SCHEMA="${ACH_DQD_RES_SCHEMA:-public}" \
    ACH_DQD_SOURCE_NAME="${ACH_DQD_SOURCE_NAME:-NA}" \
    ACH_DQD_VOCAB_SCHEMA="${ACH_DQD_VOCAB_SCHEMA:-public}" \
    ACHILLES_ENABLE_JSON_COMPRESS="${ACHILLES_ENABLE_JSON_COMPRESS:-1}" \
    ACHILLES_ENABLE_JSON_EXPORT="${ACHILLES_ENABLE_JSON_EXPORT:-0}" \
    ACHILLES_ENABLE_OPTIMIZE_ATLAS_CACHE="${ACHILLES_ENABLE_OPTIMIZE_ATLAS_CACHE:-0}" \
    ACHILLES_NUM_THREADS="${ACHILLES_NUM_THREADS:-1}" \
    ACHILLES_OUTPUT_BASE="${ACHILLES_OUTPUT_BASE:-/achilles_output}" \
    ACHILLES_RUN="${ACHILLES_RUN:-1}" \
    DQD_CHECK_LEVELS="${DQD_CHECK_LEVELS:-table_field_concept}" \
    DQD_CHECK_NAMES="${DQD_CHECK_NAMES:-0}" \
    DQD_ENABLE_JSON_TO_TABLE="${DQD_ENABLE_JSON_TO_TABLE:-0}" \
    DQD_JSON_FILE_NAME="${DQD_JSON_FILE_NAME:-DQD_Results}" \
    DQD_NUM_THREADS="${DQD_NUM_THREADS:-3}" \
    DQD_OUTPUT_BASE="${DQD_OUTPUT_BASE:-/dqd_output}" \
    DQD_RUN="${DQD_RUN:-1}" \
    DQD_SQL_ONLY="${DQD_SQL_ONLY:-0}" \
    DQD_TABLES_TO_EXCLUDE="${DQD_TABLES_TO_EXCLUDE:-0}" \
    DQD_VERBOSE_MODE="${DQD_VERBOSE_MODE:-0}" \
    DQD_WRITE_TO_TABLE="${DQD_WRITE_TO_TABLE:-0}" \
    DQD_VIZ_DISPLAY_MODE="${DQD_VIZ_DISPLAY_MODE:-normal}" \
    DQD_VIZ_HOST="${DQD_VIZ_HOST:-localhost}" \
    DQD_VIZ_JSON_PATH="${DQD_VIZ_JSON_PATH:-0}" \
    DQD_VIZ_LAUNCH_BROWSER="${DQD_VIZ_LAUNCH_BROWSER:-0}" \
    DQD_VIZ_PORT="${DQD_VIZ_PORT:-5641}" \
    DQD_VIZ_RUN="${DQD_VIZ_RUN:-1}" \
    INS_REP_CUTOFF="${INS_REP_CUTOFF:-5}" \
    INS_REP_VERBOSE="${INS_REP_VERBOSE:1}" \
    INS_REP_OUTPUT_BASE="${INS_REP_OUTPUT_BASE:-/inspection_report}" \
    INS_REP_DB_ID="${INS_REP_DB_ID:-DEFAULT}" \
    INS_REP_DB_NAME="${INS_REP_DB_NAME:-DEFAULT_NAME}" \
    INS_REP_DB_DESCRIPTION="${INS_REP_DB_DESCRIPTION:-DEFAULT_DESCRIPTION}" \
    INS_REP_BASE_URL="${INS_REP_BASE_URL:-http://localhost:8000}" \
    INS_REP_AUTHOR="${INS_REP_AUTHOR:-edenceHealth_Inspector}" \
    INS_REP_RUN="${INS_REP_RUN:-0}" \
    CAT_ENT_OUTPUT_BASE="${CAT_ENT_OUTPUT_BASE:-/catalogue_entry}" \
    CAT_ENT_DB_ID="${CAT_ENT_DB_ID:-unspecified}" \
    CAT_ENT_SRC_NAME="${CAT_ENT_SRC_NAME:-unspecified}"\
    CAT_ENT_CDM_VER="${CAT_ENT_CDM_VER:-5.3.0}" \
    CAT_ENT_RUN="${CAT_ENT_RUN:-0}"
    TIMESTAMP_RUN="${TIMESTAMP_RUN:-0}" \
  && true

  # defaults determined by container structure
  export \
    DB_DRIVER_PATH="${DB_DRIVER_PATH:-/usr/local/lib/R/site-library/DatabaseConnectorJars/java/}" \
  && true

  # log the running config
  set | while read -r config_var; do
    case "$config_var" in
      *PASSWORD*)
        # don't log passwords
        continue
        ;;

      ACH_DQD_*)
        warn "ENTRYPOINT" "joint config:" "$config_var"
        ;;

      ACHILLES_*)
        warn "ENTRYPOINT" "achilles-only config:" "$config_var"
        ;;

      DQD_*)
        warn "ENTRYPOINT" "dqd-only config:" "$config_var"
        ;;

      INS_REP_*)
        warn "ENTRYPOINT" "inspection-report-only config:" "$config_var"
        ;;

      CAT_ENT*)
        warn "ENTRYPOINT" "catalogue-entry-only config:" "$config_var"
        ;;

      *)
        continue
        ;;
    esac
  done

  # execute r scripts based on run parameters
  if [ "$ACHILLES_RUN" -eq 1 ] && [ "$DQD_RUN" -eq 1 ] && [ "$DQD_VIZ_RUN" -eq 1 ]; then
    exec /app/ach_and_dqd.r
  elif [ "$ACHILLES_RUN" -eq 1 ] && [ "$DQD_RUN" -eq 0 ] && [ "$DQD_VIZ_RUN" -eq 0 ]; then
    exec /app/achilles.r
  elif [ "$ACHILLES_RUN" -eq 0 ] && [ "$DQD_RUN" -eq 0 ] && [ "$DQD_VIZ_RUN" -eq 1 ]; then
    exec /app/dqd_viz.r
  elif [ "$ACHILLES_RUN" -eq 0 ] && [ "$DQD_RUN" -eq 1 ]; then
    warn "DQD Running without Achilles. Run may fail if Achilles has not been executed previously."
    exec /app/dqd.r
  elif [ "$ACHILLES_RUN" -eq 0 ] && [ "$DQD_RUN" -eq 0 ] && [ "$DQD_VIZ_RUN" -eq 0 ] && [ "$INS_REP_RUN" -eq 1 ]; then
    exec /app/inspection_report.r
  elif [ "$ACHILLES_RUN" -eq 0 ] && [ "$DQD_RUN" -eq 0 ] && [ "$DQD_VIZ_RUN" -eq 0 ] && [ "$INS_REP_RUN" -eq 0 ] && [ "$CAT_ENT_RUN" -eq 1 ]; then
    exec /app/catalogue_entry.r
  else
    warn "Combination of run parameters not allowed. No scripts executed."
  fi
}

main "$@"
