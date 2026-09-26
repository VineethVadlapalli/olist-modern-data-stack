"""Dagster orchestration for the Olist modern data stack.

Asset graph:  raw Olist CSVs (downloaded)  ->  dbt staging  ->  dbt marts
dbt tests are attached to their models as Dagster asset checks.
"""

import sys
from pathlib import Path

import dagster as dg
from dagster_dbt import DbtCliResource, DbtProject, dbt_assets

ROOT = Path(__file__).resolve().parents[1]
sys.path.append(str(ROOT / "scripts"))
from download_data import FILES, download  # noqa: E402

dbt_project = DbtProject(project_dir=ROOT / "olist_dbt", profiles_dir=ROOT / "olist_dbt")
dbt_project.prepare_if_dev()

# One asset per raw file. The keys match dbt's source names, so Dagster draws raw -> staging lineage.
RAW_SPECS = [
    dg.AssetSpec(
        key=["olist", name.removesuffix(".csv")],
        group_name="raw",
        kinds={"csv"},
        description=f"Raw Olist file {name}, downloaded from the public dataset mirror.",
    )
    for name in FILES
]


@dg.multi_asset(specs=RAW_SPECS, can_subset=False)
def raw_olist_files(context: dg.AssetExecutionContext):
    """Download the raw Olist CSVs (skips files that already exist)."""
    for path in download():
        yield dg.MaterializeResult(
            asset_key=["olist", path.stem],
            metadata={"size_mb": round(path.stat().st_size / 1e6, 1), "path": str(path)},
        )


@dbt_assets(manifest=dbt_project.manifest_path)
def olist_dbt_assets(context: dg.AssetExecutionContext, dbt: DbtCliResource):
    """Every dbt model, seed and test (tests become asset checks)."""
    yield from dbt.cli(["build"], context=context).stream()


daily_refresh = dg.define_asset_job("daily_refresh", selection=dg.AssetSelection.all())

defs = dg.Definitions(
    assets=[raw_olist_files, olist_dbt_assets],
    jobs=[daily_refresh],
    schedules=[dg.ScheduleDefinition(job=daily_refresh, cron_schedule="0 6 * * *", execution_timezone="UTC")],
    resources={"dbt": DbtCliResource(project_dir=dbt_project)},
)
