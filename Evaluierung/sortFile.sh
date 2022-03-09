#!/bin/bash
tmpFile="tmp.txt"
filename=$1
n=1
echo "" > $tmpFile
while read line || [ -n "$line" ]; do
# reading each line1
if [[ "$line" =~ (.*)\[(.*)\]\)\. ]]; then
	var=$(echo "${BASH_REMATCH[2]}" | tr -d " " | tr "," "\n" | sort | paste -s -d",")
	echo "${BASH_REMATCH[1]}[$var])." >> $tmpFile
else
	echo "$line" >> $tmpFile
fi
n=$((n+1))
done < $filename
sort $tmpFile | grep '\S' > $filename
rm $tmpFile