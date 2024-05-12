/******************************************************************************
 * 
 * 
 ******************************************************************************/
#include<stdio.h>
#include<stdlib.h>
#include <fcntl.h>
#include<unistd.h>
#include<sys/wait.h>
#include "systemcalls.h"

#define DEBUG               0
/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{
    /*
    * TODO  add your code here
    *  Call the system() function with the command set in the cmd
    *   and return a boolean true if the system() call completed with success
    *   or false() if it returned a failure
    */
    int rVal = system( cmd );

#if defined(DEBUG) && DEBUG
    printf( "CMD: [%s], return=%d\n", cmd, rVal );
#endif

    return ( rVal ? false : true );
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);

    char* command[count+1];

    for(int i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }

    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    // REMOVED: command[count] = command[count];
    va_end(args);

    /*
    * TODO:
    *   Execute a system command by calling fork, execv(),
    *   and wait instead of system (see LSP page 161).
    *   Use the command[0] as the full path to the command to execute
    *   (first argument to execv), and use the remaining arguments
    *   as second argument to the execv() command.
    *
    */
    #if defined(DEBUG) && DEBUG
        printf( "CMD count=%d\n", count );

        for(int i=0; i<count; i++)
            printf( " CMD[%d]: [%s]\n", i, command[i] );

    #endif

    int pid = fork();

    if( -1 == pid )
    { // call to fork() failed
        return false;
    }
    else if( 0 == pid )
    { // Inside the child process
        #if defined(DEBUG) && DEBUG
            printf( "Inside child process: %d\n", getpid() );
            printf( "--> execv( %s, %s )\n", command[0], command[1] );
        #endif

        int execErr = execv( command[0], command );
        #if defined(DEBUG) && DEBUG
                printf( "FAIL 0: Return not expected. Must be an execv error: %d\n", execErr );
        #else
            execErr = execErr;
        #endif
    }
    else
    { // Inside the parent process
        int stat;
        #if defined(DEBUG) && DEBUG
            printf( "Inside parent process: %d, with child: %d\n", getpid(), pid );
        #endif
        wait( &stat );
        if( WIFEXITED( stat ) )
        {
            #if defined(DEBUG) && DEBUG
                printf( "Exit status: %d\n", WEXITSTATUS( stat ) );
            #endif

            if ( WEXITSTATUS( stat ) != 0 )
            {
                return false;
            }
        }
        else if( WIFSIGNALED( stat ) )
        {
            psignal( WTERMSIG( stat ), "Exit Signal" );
            return false;
        }

    }

    return true;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    // REMOVED --> command[count] = command[count];
    va_end(args);

    /*
    * TODO
    *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
    *   redirect standard out to a file specified by outputfile.
    *   The rest of the behaviour is same as do_exec()
    *
    */
    #if defined(DEBUG) && DEBUG
        printf( "CMD count=%d, outputfile=%s\n", count, outputfile );

        for(int i=0; i<count; i++)
            printf( " CMD[%d]: [%s]\n", i, command[i] );

    #endif

    int pid = fork();

    if( -1 == pid )
    { // call to fork() failed
        return false;
    }
    else if( 0 == pid )
    { // Inside the child process

        int fd = open( outputfile, O_WRONLY|O_TRUNC|O_CREAT, 0644);

        if (fd < 0)
        { 
            perror("open");
            return false;
        }
        else if (dup2(fd, 1) < 0)
        {
            perror("dup2");
            return false;
        }

        close(fd);

        #if defined(DEBUG) && DEBUG
            printf( "Inside child process: %d\n", getpid() );
            printf( "--> execv( %s, %s )\n", command[0], command[1] );
        #endif

        int execErr = execv( command[0], command );
        #if defined(DEBUG) && DEBUG
            printf( "Return not expected. Must be an execv error: %d\n", execErr );
        #else
            execErr = execErr;
            printf( "FAIL 1: Return not expected. Must be an execv error: %d\n", execErr );
        #endif

        return false;
    }
    else
    { // Inside the parent process
        int stat;
        #if defined(DEBUG) && DEBUG
            printf( "Inside parent process: %d, with child: %d\n", getpid(), pid );
        #endif
        wait( &stat );
        if( WIFEXITED( stat ) )
        {
            #if defined(DEBUG) && DEBUG
                printf( "Exit status: %d\n", WEXITSTATUS( stat ) );
            #endif
            if ( WEXITSTATUS( stat ) != 0 )
            {
                return false;
            }
        }
        else if( WIFSIGNALED( stat ) )
        {
            psignal( WTERMSIG( stat ), "Exit Signal" );
            return false;
        }

    }

    return true;
}
