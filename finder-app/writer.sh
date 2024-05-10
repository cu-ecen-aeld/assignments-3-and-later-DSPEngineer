#!/bin/sh
# Assignement, part 10, script for assignment 1 and assignment 2
# Author: Jose Pagan

# $1 -- a full path to a file (including filename) on the filesystem,
#       referred to below as writefile
# $2 -- a text string which will be written within this file, referred
#       to below as writestr
#
# Exits with value 1 error and print statements if any of the arguments
#   above were not specified
#
# Creates a new file with name and path writefile with content writestr,
#   overwriting any existing file and creating the path if it doesn’t exist.
#
# Exits with value 1 and error print statement if the file could not be created.
#

usage()
{
    echo "USAGE: ${0##*/} <writefile> <writestr>"
    exit 1
}

not_a_dir( )
{
##    echo "Argument FILESDIR '${0}' is not a directory"
    echo "Argument FILESDIR '${1}' is not a directory"
#    echo "Argument FILESDIR '${2}' is not a directory"
#    echo "Argument FILESDIR '${filedir}' is not a directory"
    exit 1
}

write_file( )
{
    targetfile=${1}
    contents=${2}
#    echo "Argument FILENAME '${targetfile}'"
#    echo "Argument CONTENTS '${contents}'"

    if [ -f ${targetfile} ]; then
        chmod 755 ${targetFile}
        err=$?
        if ! [ ${err} -eq 0 ]; then
            echo "ERROR (${err}): File '${targetFile}' not writable."
	    exit 1
        fi

        rm -f ${targetFile}
        err=$?
        if ! [ ${err} -eq 0 ]; then
            echo "ERROR (${err}): File '${targetFile}' not removed."
	    exit 1
        fi
    fi

    echo ${contents} > ${targetfile}
    err=$?
    if ! [ ${err} -eq 0 ]; then
        echo "ERROR (${err}): could not create '${targetFile}'."
	exit 1
    fi
    
}

# Check arguments, we need exactly 2
if [ $# -eq 2 ]
then
    filedir=${1%/*}
    filename=${1##*/}
    writestr=$2
else
    usage
fi

# Check for target directory and create one if needed
if [ $filename = $filedir ]; then
    filedir=`pwd`
elif [ $filedir = "." ] || [ $filedir = ".." ]; then
    filedir=`pwd`
fi

## Debug  information
#echo "FILEDIR=[${filedir}]"
#echo "FILENAME=[${filename}]"
#echo "WRITESTR=${writestr}"

if ! [ -d ${filedir}  ]; then

    mkdir -p ${filedir} 2>> /dev/null
    err=$?
    if ! [ $err = 0 ]; then
	echo "ERROR: (${err}): failed to crate directory '${filedir}'."
	exit 1
    fi
fi


targetFile=${filedir}/${filename}
#echo "TARGETFILE=[${targetFile}]"


write_file ${targetFile} "${writestr}"

exit 0
