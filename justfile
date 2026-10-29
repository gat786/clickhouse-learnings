set positional-arguments := false

queries_dir := "queries"
# Output format for query results; override with e.g. `just format=Vertical run foo`
format := "PrettyCompactMonoBlock"

client := "docker compose exec -T clickhouse clickhouse-client --format " + format

# List available recipes
default:
	@just --list

# Start ClickHouse and wait until it is healthy
up:
	docker compose up -d --wait

# Stop ClickHouse (data is kept)
down:
	docker compose down

# Stop ClickHouse and DELETE all data
reset:
	docker compose down -v

# Follow server logs
logs:
	docker compose logs -f clickhouse

# Open an interactive clickhouse-client shell
client:
	docker compose exec clickhouse clickhouse-client

# Run an inline query: just ch "SELECT 1"
ch query:
	@{{client}} --query "{{query}}"

# Run a .sql file from queries/: just run 01_basics  (extension optional)
run name: up
	#!/usr/bin/env bash
	set -euo pipefail
	file="{{queries_dir}}/{{trim_end_match(name, '.sql')}}.sql"
	[[ -f "$file" ]] || { echo "No such file: $file" >&2; exit 1; }
	echo "==> $file"
	{{client}} --echo --multiquery < "$file"

# Run every .sql file in queries/ in name order
run-all: up
	#!/usr/bin/env bash
	set -euo pipefail
	shopt -s nullglob
	for file in {{queries_dir}}/*.sql; do
		echo "==> $file"
		{{client}} --echo --multiquery < "$file"
	done

# List .sql files in queries/
ls:
	@ls -1 {{queries_dir}}/*.sql 2>/dev/null || echo "No queries yet. Create one with: just new <name>"

# Create a new query file: just new 02_mergetree
new name:
	#!/usr/bin/env bash
	set -euo pipefail
	file="{{queries_dir}}/{{trim_end_match(name, '.sql')}}.sql"
	[[ -e "$file" ]] && { echo "Already exists: $file" >&2; exit 1; }
	mkdir -p {{queries_dir}}
	printf -- '-- %s\n\nSELECT 1;\n' "{{name}}" > "$file"
	echo "Created $file"
