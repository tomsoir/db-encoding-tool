#!/bin/bash

# ===================================================================================================
# Description:
#       Script will decode old WINDOW-1251 file formate into UTF-8
#
# Copyright:
#       Many thanks for https://2cyr.com and to bad that there is no public API :)
#       Inital https://2cyr.com site settongs to decode the broken file:
#           1. Expert: source encoding: UTF-8
#           1. Displayed as: WINDOWS-1252
#
# Program plan:
#       1. Read file line by line to collect common metrics (number of lines, etc...)
#       1. Read file line by line to decode them
#           1.1 Find bad line
#           1.1 Send HTTP-request to https://2cyr.com to decode it
#           1.1 Parse the response (plane text HTML)
#           1.1 Replace bad charset line with decoded UTF-8 line
#           1.1 Print Result
#
# Script usage example:
#       $ source convert.sh /Users/tomsoir/Desktop/EXAMPLE.sql
# ===================================================================================================

INPUT=$1                  # file path
BAD_SYMBOL="Ð"            # bad symbol for test
MAX_TIMOUT=2              # seconds
LINE_NUMBER=1             # line counter
LINES_TO_REPLACE_LEFT=0
LINES_TO_REPLACE_TOTAL=0

# 
# Helpers
# 
function increament_line_number() {
  ((LINE_NUMBER++))
  echo -ne "$LINE_NUMBER"'\r'
}

function update_number_lines_to_replace() {
  local DECREASE=$1
  if [[ $DECREASE = 1 ]]
      then
          ((LINES_TO_REPLACE_LEFT--))
      else
          ((LINES_TO_REPLACE_TOTAL++))
          LINES_TO_REPLACE_LEFT=$LINES_TO_REPLACE_TOTAL
  fi
}

function read_file_by_line() {
  local CALLBACK="$1"
  local WITH_LINE_COUNTER="$2"
  # Read all lines of sended file path
  while IFS= read -r line
  do
    # Test if line has a bad symbol
    if [[ "$line" == *"$BAD_SYMBOL"* ]]; then
      $CALLBACK "$line"

      # Decreas the number of lines left to replase
      update_number_lines_to_replace 1
    fi

    if [[ -n "$WITH_LINE_COUNTER" ]]
        then
            # Increas line number (to see where we are)
            increament_line_number
    fi
  done < "$INPUT"
}

function request_line_decode() {
  local LINE="$1"
  # Encode line for next 
  local ENCODED_VALUE=$(python -c "import urllib; print urllib.quote('''${line}''')")
  # Request string encoding
  local RESPONSE=$(curl 'https://2cyr.com/decode/?lang=en' \
    -H 'authority:2cyr.com' \
    -H 'cache-control:max-age=0' \
    -H 'upgrade-insecure-requests:1' \
    -H 'origin:https://2cyr.com' \
    -H 'content-type:application/x-www-form-urlencoded' \
    -H 'user-agent:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.125 Safari/537.36' \
    -H 'accept:text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
    -H 'sec-fetch-site:same-origin' \
    -H 'sec-fetch-mode:navigate'\
    -H 'sec-fetch-user:?1' \
    -H 'sec-fetch-dest:document' \
    -H 'referer:https://2cyr.com/decode/?lang=en' \
    -H 'accept-language:en,en-US;q=0.9,ru;q=0.8' \
    -H 'cookie:PHPSESSID=9b2fcfb6de8eab22af4263d106149fcd; SERVERID102299=220112|Xz9wA|Xz9h8' \
    --data-raw "text=${ENCODED_VALUE}&ident=%3AUTF-8%3AWINDOWS-1252&sample=&src=UTF-8&dsp=WINDOWS-1252&prf=&expert=OK" \
    --compressed)
  # remove all new lines in text
  local RESPONSE_SINGLE_STR=$(echo "$RESPONSE" | perl -0777 -pe 's/\n+//g')
  # get our initial decoded line
  local RESPONSE_DECODED_LINE=$(echo "$RESPONSE_SINGLE_STR" | LANG=C sed -n 's/.*tt_output\">\(.*\)<\/tt><\/p>.*/\1/p')
  # Reanimate smart quotes
  local RESPONSE_WITH_QUOTES=$(echo "$RESPONSE_DECODED_LINE" | sed "s/&#039;/'/g")
  # Return result
  echo "$RESPONSE_WITH_QUOTES"
}

function replace_line_in_file() {
  local FILE="$1"
  local LINE_NUMBER="$2"
  local REPLACEMENT="$3"
  # Escape backslash, forward slash and ampersand for use as a sed replacement
  local REPLACEMENT_ESCAPED=$( echo "$REPLACEMENT" | sed -e 's/[\/&]/\\&/g' )
  # Replace and update file (.bak is for MAC OS)
  sed -i ".bak" "${LINE_NUMBER}s/.*/${REPLACEMENT_ESCAPED}/" "$FILE"

  # Print result
  echo " --------------------------------------- "
  echo " Line (currect position): ${LINE_NUMBER}:"
  echo " Lines to replace: ${LINES_TO_REPLACE_TOTAL} / ${LINES_TO_REPLACE_LEFT}"
  echo " Text: ${REPLACEMENT_ESCAPED}"
  echo " "
  echo " "
  echo " ======================================= "
}

function decode_line() {
  local LINE=$1
  # Decode the line
  DECODED_LINE=$(request_line_decode $LINE)
  # Replace bad line with decoded one (right in the file)
  replace_line_in_file $INPUT $LINE_NUMBER "${DECODED_LINE}"
  # Random sleep timeout to emulate user behaviour
  sleep $((RANDOM % MAX_TIMOUT))
}

function init () {
  # Count how many lines left to replace
  # Count how many lines total to replace
  read_file_by_line update_number_lines_to_replace
  echo "LINES TO REPLACE: ${LINES_TO_REPLACE_TOTAL}"

  # Decode lines one by one
  read_file_by_line decode_line 1
}

#
# RUN SCRIPT
#
init
