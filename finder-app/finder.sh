#!/bin/sh
# Assignement, part 9, script for assignment 1 and assignment 2
# Author: Jose Pagan

# $1 -- path to a directory on the filesystem, referred to below as filesdir
# $2 -- a text string which will be searched within these files, referred
#       to below as searchstr
#
# Exits with return value 1 error and print statements if any of the
#  parameters above were not specified
#
# Exits with return value 1 error and print statements if filesdir
#  does not represent a directory on the filesystem
#
# Prints a message "The number of files are X and the number of matching
#  lines are Y" where X is the number of files in the directory and all
#  subdirectories and Y is the number of matching lines found in respective
#  files, where a matching line refers to a line which contains searchstr
#  (and may also contain additional content).

usage()
{
    echo "USAGE: ${0##*/} <filesdir> <search>"
    exit 1
}

not_a_dir()
{
    echo "Argument FILESDIR '${filesdir}' is not a directory"
    exit 1
}

if [ $# -eq 2 ]
then
    filesdir=$1
    searchstr=$2
else
    usage
fi

if [ -d ${filesdir} ]
then
    echo "DIRECTORY: ${filesdir}"
else
    not_a_dir
fi

#echo "FILESDIR=${filesdir}"
#echo "SEARCHSTR=${searchstr}"

numfiles="`find -L ${filesdir} -type f  | wc -l`"
#echo "numfiles = ${numfiles}"
numlines="`grep -w -r -i ${searchstr} ${filesdir}/* | wc -l`"
#echo "numlines = ${numlines}"

echo "The number of files are ${numfiles} and the number of matching lines are ${numlines}"
