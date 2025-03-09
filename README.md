# LogfileTools

With the Logfile Tools, you are able to cut standard Apache web server log files into analyzable pieces, combine them, sort them 
and much more.

The Logfile Tools are **64-bit command line programs** that can be executed under Windows XP(x64) to Windows 11.

Compiles on Delphi 12.1 (29.0.52631.8427) Community Edition

To use the log file tools, simply copy them to your log files or to the system path or use the provided installer.

Download the installer here: https://go.husx.de/9

## SplitLog

To process a log file of several gigabytes, you usually need more RAM than you have installed (Murphy's Law #683).

With SplitLog you can split a single log file into small chunks of “n” lines each.

```
SplitLog.exe <FileName> [Lines]

<FileName> - Filename of the logfile to process
[Lines]    - Number of lines in each split file
```

## ConcatLog

creates a combined log file from several files, i.e. it is the counterpart to SplitLog. It is essential to ensure that ConcatLog 
processes the files in alphabetical order! However, Linux' Logrotate creates the file names of the archived logs in reverse order: 
access.log.gz.1 therefore comes after access.log.gz.2! To solve this problem, please scroll to the program “ReverseRename.exe”.

```
ConcatLog.exe <SourceFileName> <DestFileName>

<SourceFileName> - File mask with place holder of files to process
<DestFileName>   - File name for concatenated results
```

## AnonLog

anonymizes and shortens a logfile by replacing the IP address with a (partial) hash value and stripping the browser information.
I cannot remember why I created this tool in the first place, but it might be useful for GDPR requests.

```
AnonLog.exe <SourceFileName> <DestFileName>

<SourceFileName> - File name of source log file
<DestFileName>   - File name of destination log file
```

## FilterLog

It often makes sense to exclude access from search engines from the statistics. FilterLog.exe does this for you.

**Attention! FilterLog works destructively!**

FilterLog first reads a file called filter.dat line by line.

Then the files recognized from the wildcard parameter are read in one after the other and all lines in which one of the search 
terms contained in the filter.dat occurs, e.g. “GoogleBot”, “Bing” etc., are removed.

The original files are lost in this process. However, since FilterLog was originally used in a cascade together with SortLog, 
which created duplicates of the source files, this behavior was never changed.

```
FilterLog.exe <SourceFileName>

<SourceFileName> - File name of log file(s). Can contain wildcards
```

## ExtractLog

If you are looking for a specific access in a large log file for which you know the time, ExtractLog allows you to cut out 
a time-limited area of a log file for further processing. An IP address or host name is searched for (but no name resolution 
is performed!)

The output is displayed on the console and can be redirected to a file using the “>” operator.

```
ExtractLog.exe <SourceFileName> [options]

<SourceFileName>            - File name of log file
-hvalue, /hostname:value    - Filtering for <hostname>, Required argument.
[-fvalue], [/from:value]    - From date/time in format: "YYYY-MM-DDTHH:MM" You
                              cannot omit the HH:MM part.
[-tvalue], [/to:value]      - To date/time in format: "YYYY-MM-DDTHH:MM" You
                              cannot omit the HH:MM part.
[-avalue], [/around:value]  - To date/time in format: "YYYY-MM-DDTHH:MM" You
                              cannot omit the HH:MM part.
[-mvalue], [/minutes:value] - Use a time range along with the /around
                              parameter.
[-q], [/quiet]              - No extra information, just the output.
```

You should either give both the /around and /minutes parameters **OR** both the /from and /to parameters.
The parameter /quiet suppresses diagnostic output and should be used when using ExtractLog in redirects.

## SortLog

SortLog.exe is probably the best tool for archiving log files. It reads in a number of log files and sorts their contents into 
sub-files by month. The original files remain unchanged. For sorting by date/time, SortLog must read in the individual lines 
of the log files and keep at least the contents of a complete month in memory.

In order to work as efficiently as possible, SortLog first looks through the log files and calculates their lowest and highest 
dates. For the respective months, only those log files are processed in the second sorting pass that contain relevant data for 
the respective month.

All files in the current directory that begin with the word “access” are used as input files. As output SortLog.exe creates 
one file per month according to the scheme: access.YYYY.MM.log.

SortLog.exe therefore works without parameters.

## ReverseRename

In the Unix environment, the “Logrotate” tool is used, which compresses and archives log files at regular intervals. Archived 
files are then given the extension “.gz.1” with consecutive numbers. Older log files are given higher numbers. To combine such 
files with ConcatLog.exe in the correct order into one large file, you can use the ReverseRename tool.

For example, if you have the log files “access_log.gz.1” to “access.log.gz.10”, it is sufficient to enter:

```
ReverseRename.exe access.*
```

to rename the files in reverse order without confusing the times in the log files chronologically.