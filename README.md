# dbt + MCP AI Agent Integration

Objective: 
1. AI agent can read the project's lineage and documentation answer business user
questions in natural language. 
2. Run dbt commands against it.

Action :
A small dbt project that runs entirely on a laptop, linked to dbt Labs' MCP
server.
The semantic layer is a marketing campaign performance warehouse: raw ad platform
feeds landing into a star schema, with an incremental fact table, a Type 2
snapshot, and a pacing mart.

Everything runs on DuckDB. No cloud account, no credentials, no cost. Keeping
cloud cost to zero for this project

## What's in here

```
seeds/          three raw CSV feeds standing in for ad platform extracts
models/
  staging/      one view per source, renaming and typing only
  marts/        star schema: three dimensions, one fact, one reporting mart
snapshots/      Type 2 history on campaign budget and status
macros/         surrogate keys, currency conversion, a dev row limiter
tests/          three singular tests alongside the generic ones in YAML
```

### The DAG

```
raw_channels  ──> stg_channels  ──> dim_channel ─┐
raw_campaigns ──> stg_campaigns ──> dim_campaign ─┼─> fct_ad_performance
                       │                          │      (incremental)
                       │            dim_date ─────┘            │
                       └─────────> snap_campaign_budget        v
                                        (SCD2)        mart_campaign_pacing
raw_ad_spend  ──> stg_ad_spend ─────────────────────────> (fct)
```
## Quickstart

```bash
pip install dbt-duckdb
git clone <this repo> && cd dbt_mcp_demo
export DBT_PROFILES_DIR=$(pwd)

dbt seed        # load the raw CSVs
dbt build       # models, snapshot and 42 tests
dbt docs generate
```
Seeds have to load before the first `dbt build` because dbt has no dependency
edge between a seed and a source that happens to point at it. After that,
`dbt build` on its own is fine.

Query the result directly if you want to poke at it:

```bash
python -c "import duckdb; print(duckdb.connect('dev.duckdb').execute(
  'select campaign_name, budget_spent_pct, cpa_gbp from main_marts.mart_campaign_pacing order by 2 desc').fetchall())"
```

## Design decisions around test

**Surrogate keys handle nulls explicitly.** `generate_surrogate_key` coalesces
every input to a sentinel before hashing. Without that, two different business
keys containing nulls collapse onto the same hash, and the uniqueness test
fails somewhere far from the cause. dbt_utils has an equivalent macro; it is
written longhand here to keep the project dependency free and because the null
handling is the interesting part.

**Three singular tests catch things generic tests cannot.** 
Clicks above impressions on the same row means a bad join upstream. 
Negative metrics happen when a platform sends invalid traffic clawbacks. 
Spend above 110% of budget is either a pacing failure or a duplicated fact row. 

**One unit test on `stg_campaigns`** 
Check on pence to pounds conversion and the status cleanup against mock rows, 
so a regression is caught without touching the warehouse.

## The MCP integration

[dbt's MCP server](https://docs.getdbt.com/docs/dbt-ai/about-mcp) exposes the
dbt CLI and the local `manifest.json` to an MCP client. The self-hosted server
is the one that gives you CLI commands; the remote server covers dbt platform
features like the Semantic Layer and Discovery API, which need a dbt platform
account and are not used here.

Install `uv`, then point your client at the project. For Claude Desktop, in
`claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "dbt": {
      "command": "uvx",
      "args": ["dbt-mcp"],
      "env": {
        "DBT_PROJECT_DIR": "/absolute/path/to/dbt_mcp_demo",
        "DBT_PROFILES_DIR": "/absolute/path/to/dbt_mcp_demo",
        "DBT_PATH": "/absolute/path/to/dbt",
        "DBT_HOST": "",
        "DBT_TOKEN": "",
        "DISABLE_SEMANTIC_LAYER": "true",
        "DISABLE_DISCOVERY": "true"
      }
    }
  }
}
```

`which dbt` gives you `DBT_PATH`. 

Run `dbt docs generate` because the lineage tools read `target/manifest.json`. 
Set `DBT_MCP_LOG_LEVEL=DEBUG` if the client shows no tools.

The same config file is included as `mcp_config.example.json`.

### Things worth asking the agent

- What does `fct_ad_performance` depend on, and what breaks if I change its grain?
- Which models have no tests?
- Run the tests on `mart_campaign_pacing` and explain any failure.
- Build only the models downstream of `stg_ad_spend`.
- Why is this model incremental, and what does the lookback window do?

Lineage questions are where it earns its keep. The agent reads `manifest.json`
directly, so it answers from the actual compiled graph rather than guessing
from the SQL text.

### The security bit

dbt's own documentation flags that giving a client dbt command access can
modify models, sources and warehouse objects. On a local DuckDB file that is
harmless. 
Pointing the same config at a production warehouse is a different
decision, and the sensible default is to disable the write commands and scope
the credential to read-only. That trade-off is the most interesting part of
the exercise and the reason this project targets a local file.
Best to add config : 
        "DISABLE_DBT_CLI": "true"  


## Known limitations

- Seeds stand in for real ingestion. There is no extract layer.
- `dim_date` is hardcoded to 2026 rather than derived from the fact table range.
- No CI. A GitHub Action running `dbt build` on pull requests is the obvious
  next step, along with `dbt build --select state:modified+` against a stored
  manifest.
- No exposures defined, so the lineage stops at the mart rather than reaching
  a dashboard.
