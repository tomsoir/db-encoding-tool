# Description:
Script decodes an old WINDOW-1251 file (line by line) into the UTF-8 formate

# Script usage example:
```
$ source convert.sh /Users/tomsoir/Desktop/EXAMPLE.sql
```

# Program plan:
1. Read file line by line to collect common metrics (number of lines, etc...)
1. Read file line by line to decode them
    1. Find the bad line
    1. Send HTTP-request to https://2cyr.com to decode it
    1. Parse the response (plain text HTML)
    1. Replace bad charset line with decoded UTF-8 line
    1. Print Result

# Copyright:
Many thanks for https://2cyr.com and too bad that there is no public API :)
Initial https://2cyr.com site settings to decode the broken file:
   1. Expert: source encoding: UTF-8
   1. Displayed as: WINDOWS-1252
