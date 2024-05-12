/*******************************************************************************
**
** Assignement 2, part 3, C-writer application to rpelace writer.sh from assignment 1
** Author: Jose Pagan
**
** $1 -- a full path to a file (including filename) on the filesystem,
**       referred to below as writefile
** $2 -- a text string which will be written within this file, referred
**       to below as writestr
**
** Exits with value 1 error and print statements if any of the arguments
**   above were not specified
**
** Creates a new file with name and path writefile with content writestr,
**   overwriting any existing file and creating the path if it doesn’t exist.
**
** Exits with value 1 and error print statement if the file could not be created.
**
*******************************************************************************/
#include <syslog.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#define LOGFILE                 "syslog"
#define LOGOPTIONS              LOG_CONS | LOG_PID | LOG_NDELAY

#define MAX_STRING_LENGTH       1024
#define DEBUG                   1

// Error types:
typedef enum {
    MSG=0,
    INFO,
    WARN,
    ERR,
    MAX_DBG_ERR  
} DBG_ERR;

// Error messages, to match types
char errorString[ MAX_DBG_ERR ][30] =
{
    "MESSAGE", "INFO", "WARNING", "ERROR"
};


int usage(char* progName)
{
    printf( "USAGE: %s <writefile> <writestr>\n", progName );
    syslog( LOG_ERR, "USAGE: %s <writefile> <writestr>\n", progName );
    return 1;
}

char* getLastToken( char * tokenString, char delimiter )
{
  char *retStr = NULL;
  char *searchStr = tokenString + strlen(tokenString);

    do
    {
        if( searchStr[0] != delimiter)
        {
        searchStr--;
        }
        else
        {
            retStr = &searchStr[1];
            break;
        }

    } while( tokenString != searchStr );

    return retStr;
}

int concatArguments( int argc, char **argv, char* retStr )
{
    int finalLength = 0;
    static char newStr[MAX_STRING_LENGTH+1] = {};

    if( NULL != retStr )
    {
        strcpy( newStr ,argv[0] );
        finalLength = strlen(newStr);

        for( int i=1; i<argc; i++ )
        {
            finalLength += sprintf( &newStr[finalLength], " %s", argv[i] );
        }

        if( finalLength < MAX_STRING_LENGTH )
        {
            strcpy( retStr, newStr );
        }
        else
        {
            finalLength = 0;
        }

    }

    return finalLength;
}

int writeFile( char* targetFile, char* outputString )
{
    int retErr = 0;

    if( NULL == targetFile )
    {
        syslog( LOG_ERR, "Target file is NULL or missing" );
        retErr = 1;
    }
    else if( NULL == outputString )
    {
        syslog( LOG_ERR, "Output string is NULL or missing" );
        retErr = 2;
    }
    else
    {
        syslog( LOG_INFO, "Writing \"%s\" to \"%s\" ", outputString, targetFile );
        int fp = open( targetFile, O_WRONLY | O_CREAT | O_TRUNC, 0664 );
        retErr = write( fp, outputString, strlen(outputString) );
        close(fp);
    }


    return retErr;
}


int main( int argc, char **argv)
{
    int retVal = 1;
    // capture the file name:
    char *execName=argv[0];

    // Use the syslog for logging
    // Example: openlog ("syslog", LOG_CONS | LOG_PID | LOG_NDELAY, LOG_LOCAL1);
    openlog( LOGFILE, LOGOPTIONS, LOG_USER );

    // First log message, when program starts
    syslog( LOG_INFO, "Program %s started by User %d", argv[0], getuid ());


#if 1 || defined(DEBUG) && ( DEBUG > 0 )
    printf( "Arg[0]: %s\n", execName );
    printf( "Arg[1]: %s\n", argv[1] );
#endif

    // Tease out the exectuable file name
    execName = getLastToken( execName, '/' );
#if defined(DEBUG) && ( DEBUG > 0 )
    printf( "Executable: %s\n", execName );
#endif

    char conentString[1024] = {0};

    if( argc < 3 )
    {
        syslog( LOG_ERR, "missing command arguments, requres 2, provided %d\n", argc-1 );
        usage( execName );
    }
    else if( argc > 3 )
    {
        int argLen = concatArguments( argc-2, &argv[2], conentString );
#if defined(DEBUG) && ( DEBUG > 0 )
        printf( "INFO: extra command arguments, requres 2, provided %d\n", argc-1 );
        printf( "INFO: concatenated argument(s) length = %d characters.\n", argLen );
#endif
        syslog( LOG_INFO, "INFO: extra command arguments, requres 2, provided %d\n", argc-1 );
        syslog( LOG_INFO, "concatenated argument(s) length = %d characters.\n", argLen );
    }

    retVal= writeFile( argv[1],conentString );

    syslog (LOG_INFO, "Program %s completed for User %d", argv[0], getuid ());

    closelog();

    return retVal;
}
    
