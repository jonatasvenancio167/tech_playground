#!/usr/bin/env bash
set -euo pipefail

cd /app

bundle config set path "${BUNDLE_PATH:-/usr/local/bundle}"
bundle config set without "${BUNDLE_WITHOUT:-production}"
bundle check || bundle install

export RAILS_ENV="${RAILS_ENV:-development}"
export DATABASE_URL="${DATABASE_URL:-postgres://postgres:postgres@db:5432/rails_dev}"

bundle exec rails db:prepare
exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}
