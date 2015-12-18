#!/bin/bash
set -ueo pipefail
script_dir="$(cd "$(dirname "$0")"; pwd)"
cd "$script_dir"
/usr/bin/env ruby src/main.rb "$@"
