#!/usr/bin/env bash
root=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

fswatch -0 -o $root/values | xargs -0 -n 1 -I {} $root/bin/gen-values.sh
