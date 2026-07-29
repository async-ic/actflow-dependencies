#!/bin/sh

#
# Copyright 2026, 2022 Ole Richter - Technical University of Denmark, University of Groningen

#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Tees stdin into logfile $1 while emitting only a progress marker every $2 lines
# (default 25). Keeps the CI console short (long logs get truncated) yet alive
# (no long silent stretch that marks the job defunct). Full log stays in the file.
#

file=$1
threshold=${2:-25}

: > "$file"

num=0
col=0
count=0
while IFS= read -r line || [ -n "$line" ]
do
	printf '%s\n' "$line" >> "$file"
	count=$((count + 1))
	if [ "$count" -eq "$threshold" ]
	then
		count=0
		num=$((num + 1))
		col=$((col + 1))
		printf '%d..' "$num"
		if [ "$col" -eq 10 ]
		then
			col=0
			echo
		fi
	fi
done
if [ "$col" -ne 0 ]
then
	echo
fi
