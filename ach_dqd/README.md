# Dockerized Achilles and Data Quality Dashboard

Debian-based image running R with assorted OHDSI packages required to run these QC/AT tools for OMOP CDM output.

* Parameters are set via env variables, which can be modified using a `docker-compose.yml` file.

* In the current build, the port 5641 can be exposed by explicitly passing the argument `--service-ports` in the `docker-compose run` command.
