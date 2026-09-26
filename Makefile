.PHONY: setup data build test docs dagster clean

export DBT_PROFILES_DIR := $(CURDIR)/olist_dbt

setup:      ## install Python 3.12 env + dependencies (needs uv)
	uv sync

data:       ## download the raw Olist CSVs into data/raw
	uv run python scripts/download_data.py

build: data ## run every dbt model, seed and test
	cd olist_dbt && uv run dbt build

test:       ## run only the dbt tests
	cd olist_dbt && uv run dbt test

docs:       ## generate and open dbt docs (lineage graph + column docs)
	cd olist_dbt && uv run dbt docs generate && uv run dbt docs serve

dagster:    ## start the Dagster UI at http://localhost:3000
	uv run dagster dev

clean:
	rm -rf olist_dbt/target olist_dbt/logs data/warehouse/*.duckdb
