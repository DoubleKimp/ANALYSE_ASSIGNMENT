#!/usr/bin/env bash


# Name: Karsten Keemink
# Student number: 1039658

# sometimes without using sudo the make uninstall and make install commands didnt work properly. same for the chmod command.

# Define global variable here

# TODO: Add required and additional packagenas dependecies 
# for your implementation
declare -a dependecies=("unzip" "wget" "make" "curl" "gcc" "git")
declare -a packages=("nosecrets" "pywebserver")

# TODO: define a function to handle errors
# This funtion accepts two parameters one as the error message and one as the command to be excecuted when error occurs.
function handle_error() {
    # Do not remove next line!
    echo "function handle_error"

   # TODO Display error and return an exit code
   echo "Error: $1"
   if [[ ! $2 -eq "" ]]; then
        $2
   fi

   exit 1
   
}

# Function to solve dependencies
function setup() {
    # Do not remove next line!
    echo "function setup"

    # TODO check if nessassary dependecies and folder structure exists and ✓
    # print the outcome for each checking step ✓

    # TODO installation from online package requires values for 
    # package_name package_url install_dir 

    # TODO check if required dependency is not already installed otherwise install it ✓
    # if a a problem occur during the this process  ✓
    # use the function handle_error() to print a messgage and handle the error ✓

    # TODO check if required folders and files exists before installations ✓
    # For example: the folder ./apps/ and the file "dev.conf" ✓

    #check if required dependencies are installed using a for loop
    echo "Checking if required dependencies are installed"
    for dependency in "${dependecies[@]}"; 
    do
        #the actual check of the dependencies existence
        #command -v checks if the package exists &> /dev/null redirects the output to null so the user does not see it
        if ! command -v "$dependency" &> /dev/null;
        #if the dependency is not found handle the error
        then
            echo "$dependency has not been found, trying to install it"
            #try to install the dependency or send an error message

            #sudo is sometimes needed for some dependencies, to make this code without me repeating myself i assume it for all dependencies.
            #if this is not allowed i would be very interrested to the reason why this would hurt the security of the system and the code.
            #in my opinion this would never be seen as an error in a real world situation.

            #the -y flag auto answers yes to the question if the user wants to install the dependency
            sudo apt-get install -y $dependency || handle_error "$dependency has not been installed. Install the dependency using: sudo apt-get install $dependency"
            
        else
            echo "$dependency has been found"
        fi
    done

    #check if the dev.conf file is present
    echo "Checking if dev.conf file is present"
    #source the dev.conf file to use the variables in it
    source "dev.conf" || handle_error "dev.conf is not found"

    #check if test.json is present
    echo "Checking if test.json file is present"
    #check if the file exists
    if [ ! -f "test.json" ]; 
    then
        #if the file does not exist handle the error
        handle_error "test.json is not found"  
    else
        echo "test.json is found"
    fi


    #check if the folder structure is present, else create it
    echo "Checking if folder structure is present"
    #the -d flag checks if the directory exists
    if [ ! -d "$INSTALL_DIR" ]; 
    then
        echo "Folder structure to $INSTALL_DIR does not exist"
        echo "Creating the folder structure"
        #create the folder structure using -p to create any nessesary parent folders if they do not exist
        mkdir -p "$INSTALL_DIR"
        echo "Created folder structure to $INSTALL_DIR"
    else
        echo "Folder $INSTALL_DIR exists"
    fi

}

# Function to install a package from a URL
# TODO assign the required parameter needed for the logic
# complete the implementation of the following function.
function install_package() {
    # Do not remove next line!
    echo "function install_package"

    # TODO The logic for downloading from a URL and unizpping the downloaded files of different applications must be generic

    # TODO Specific actions that need to be taken for a specific application during this process should be handeld in a separate if-else

    # TODO Every intermediate steps need to be handeld carefully. error handeling should be dealt with using handle_error() and/or rolleback()

    # TODO If a file is downloaded but cannot be zipped a rollback is needed to be able to start from scratch
    # for example: package names and urls that are needed are passed or extracted from the config file

    # TODO check if the application-folder and the url of the dependency exist
    # TODO create a specific installation folder for the current package

    # TODO Download and unzip the package
    # if a a problem occur during the this proces use the function handle_error() to print a messgage and handle the error

    # TODO extract the package to the installation folder and store it into a dedicated folder
    # If a problem occur during the this proces use the function handle_error() to print a messgage and handle the error

    # TODO this section can be used to implement application specifc logic
    # nosecrets might have additional commands that needs to be executed
    # make sure the user is allowed to remove this folder during uninstall

    #get the application name from the first parameter
    application_name="$1"

    #use the app name to check which app is being installed and use a switch case to handle the different apps
    case "$application_name" in 
    "nosecrets" )
        # get the URL for nosecrets from the dev.conf file
        url="$APP1_URL"
        echo "URL for nosecrets is $url"

        echo "$application_name is being installed"
        # create a folder for the application and save directory path to variable
        mkdir -p "$INSTALL_DIR/$application_name"
        app_directory="./$INSTALL_DIR/$application_name"


    ;;
    "pywebserver" )
        # get the URL for pywebserver from the dev.conf file
        url="$APP2_URL"
        echo "URL for pywebserver is $url"

        echo "$application_name is being installed"

        # create a folder for the application and save directory path to variable
        mkdir -p "$INSTALL_DIR/$application_name"

        app_directory="./$INSTALL_DIR/$application_name"
        echo "Directory for $application_name is $app_directory"


    ;;
    * )
        #if the app name is not found handle the error
        handle_error "Application name not found. Check if the application name is correct"
    esac

    #download the file from the url
    echo "Downloading $application_name from $url"

    download_app "$url" "$directory" "$application_name"

    #unzip the file
    echo "Unzipping $application_name"
    unzip_app "$url" "$app_directory"


    #if it is nosecrets run the make command for nms and install
    if [[ $application_name == "nosecrets" ]]; then
        echo "Running make for nms and install"
        cd "$directory/no-more-secrets-master" || handle_error "Could not find no-more-secrets-master folder to make nms and run make install"
        #run the make command for nms and rollback on error
        make nms || rollback_nosecrets "nms"

        #run the make install command and rollback on error
        sudo make install || rollback_nosecrets "install"
        #go back to main directory
        cd ..
        cd ..
        cd ..
    fi

    #if it is pywebserver run the make command for pywebserver
    if [[ $application_name == "pywebserver" ]]; then
        echo "running chmod for pywebserver"
        #run the chmod command to make the file executable
        sudo chmod +x "$directory/webserver-master/webserver" || rollback_pywebserver "Chmod"
        echo "pywebserver is now functional"
    fi
}

# Function to download a file from a URL
function download_app(){
    #get the url and directory from the parameters
    url="$1"
    directory="$2"
    app_name="$3"
    
    echo "Downloading $url to $directory"
    #download the file from the url and save it to the directory
    wget -P "$directory" "$url" || rollback_$app_name "download"
}

# Function to unzip a file
function unzip_app(){
    #get the file name and directory from the parameters
    file_base="$(basename "$1")"
    directory="$2"
    
    #get the name of the app that is being installed
    app_name="$(basename "$directory")"

    echo "Unzipping $file_name to $directory"

    #unzip the file to the directory
    unzip "$file_base" -d "$directory"|| rollback_$app_name "unzip"
    rm "$file_base"
    
}


function rollback_nosecrets() {
    # Do not remove next line!
    echo "function rollback_nosecrets"
    


    # TODO rollback intermiediate steps when installation fails
    echo "Rolling back nosecrets installation"

    #display error message
    case $1 in 
    "download" )
        echo "Could not download nosecrets"
        ;;
    "unzip" )
        echo "Could not unzip nosecrets"
        ;;
    "nms" )
        echo "Could not make nms"
        ;;
    "install" )
        echo "Could not make install nosecrets"
        make clean
        ;;
    * )
        echo "Could not rollback nosecrets"

        #clean make just in case.
        make clean


    esac

    #remove the package and folder structure
    echo "Removing nosecrets"
    uninstall_nosecrets
    handle_error "Installing and/or starting nosecrets failed. The folder has been rolled back to its original state. please check the installation and try again."


    

}

function rollback_pywebserver() {
    # Do not remove next line!
    echo "function rollback_pywebserver"

    # TODO rollback intermiediate steps when installation fails
    echo "Rolling back pywebserver installation"
    case $1 in
    "download" )
        echo "Could not download pywebserver"
        ;;

    "unzip" )
        echo "Could not unzip pywebserver"
        ;;

    "chmod" )
        echo "Could not make pywebserver executable"
        ;;
    * )
        echo "Could not rollback pywebserver"
    esac

    #remove the package and folder structure
    echo "Removing pywebserver"
    #run uninstall function to clean up the folder structure
    uninstall_pywebserver

    #handle the error
    handle_error "Installing and/or starting has pywebserver failed. The folder has been rolled back to its original state. please check the installation and try again."

}

function test_nosecrets() {
    # Do not remove next line!
    echo "function test_nosecrets"

    # TODO test nosecrets
    # kill this webserver process after it has finished its job

    #start the test
    echo "Starting nosecrets test"

    #check if nosecrets is installed

    #get the result of the test and pass it to a variable
    ls -l | nms &
    results=$!

    #check if nosecrets is working using the results of the test
    if [[ $results -gt 0 ]]; then
        echo "nosecrets is working"
        kill $results &
    else
        #if an error occurs handle the error
        handle_error "nosecrets error: $results"
    fi



}

function test_pywebserver() {
    # Do not remove next line!
    echo "function test_pywebserver"    

    # TODO test the webserver
    # server and port number must be extracted from config.conf
    # test data must be read from test.json  
    # kill this webserver process after it has finished its job

    #start the test
    echo "Starting pywebserver test"
    echo "Host: $WEBSERVER_IP on port: $WEBSERVER_PORT"

    #start the webserver on the background
    $INSTALL_DIR/pywebserver/webserver-master/webserver "$WEBSERVER_IP":"$WEBSERVER_PORT" &

    #get the pid to kill the process
    pid_id=$!

    #check if the webserver is working
    curl localhost:8008/ -H "Content-Type: application/json" -X POST --data @test.json

    
    
    #kill the webserver
    kill $pid_id

}

function uninstall_nosecrets() {
    # Do not remove next line!
    echo "function uninstall_nosecrets"  

    #TODO uninstall nosecrets application
    cd "$INSTALL_DIR/nosecrets/no-more-secrets-master" || handle_error "Could not find nosecrets folder"

    #remove and uninstall nosecrets
    echo "Removing nosecrets"
    sudo make uninstall || handle_error "Could not uninstall nosecrets"
    echo "nosecrets has been removed"
    #go back to main directory
    cd ..
    cd ..
    cd ..
    echo "Removing nosecrets folder"
    rm -rf "$INSTALL_DIR/nosecrets" || handle_error "Could not remove nosecrets folder"

    echo "nosecrets has been removed"

}

function uninstall_pywebserver() {
    echo "function uninstall_pywebserver"    
    #TODO uninstall pywebserver application

    #remove and uninstall pywebserver, remove the folder structure (according to the documentation only the folder structure of pywebserver needs to be removed)
    echo "Removing pywebserver"
    rm -rf "$INSTALL_DIR/pywebserver" || handle_error "Could not remove pywebserver folder"
}

#TODO removing installed dependency during setup() and restoring the folder structure to original state
function remove() {
    # Do not remove next line!
    echo "function remove"

    # Remove each package that was installed during setup
    source "dev.conf" || handle_error "dev.conf is not found"

    #call the uninstall functions for each package if the package is installed
    for package in "${packages[@]}";
    do
        if [[ -d $INSTALL_DIR/$package ]]; then
            echo "Uninstalling $package"
            uninstall_$package
        fi
    done

    #remove the folder structure
    echo "Removing folder structure"
    rm -rf "$INSTALL_DIR"

    #remove the dependencies
    echo "Now removing the dependecies"
    for dependency in "${dependecies[@]}";
    do
        #check if it is one of the dependecies the assignment told us to delete: make, gcc, git
        case $dependency in "make" | "gcc" | "git")
            #if it is one of the dependecies the assignment told us to delete, delete it
            echo "Removing $dependency"
            sudo apt-get remove -y "$dependency" || handle_error "Could not remove $dependency" 
            echo "$dependency has been removed"
            ;;
        * )
            #if it is not one of the dependecies the assignment told us to delete, go on to the next dependency
            continue;;
        esac
    done

}

function main() {
    # Do not remove next line!
    echo "function main"

    # TODO
    # Read global variables from configfile
    source "dev.conf" || handle_error "dev.conf is not found"

    # Get arguments from the commandline
    # Check if the first argument is valid
    # allowed values are "setup" "nosecrets" "pywebserver" "remove"
    # bash must exit if value does not match one of those values
    # Check if the second argument is provided on the command line
    # Check if the second argument is valid
    # allowed values are "--install" "--uninstall" "--test"
    # bash must exit if value does not match one of those values

    # Execute the appropriate command based on the arguments
    # TODO In case of setup
    # excute the function check_dependency and provide necessary arguments
    # expected arguments are the installation directory specified in dev.conf

    # get commands from arguments
    command1="$1"
    command2="$2"



    #check the purpose of command 1
    case $command1 in "setup" | "nosecrets" | "pywebserver" | "remove");;
    * )
        #if the command is not found handle the error
        handle_error "Command not found. Check if the command is correct";;
    esac



    #check the purpose of command 2 if it exists
    if [[ ! $command2 -eq "" ]]; then
        case $command2 in "--install" | "--uninstall" | "--test");;
        * )
            #if the command is not found handle the error
            handle_error "Command for second argument not found. Check if the command is correct";;
        esac
    fi

    #execute the function connected to the commands
    case $command1 in
        "setup" )
            #if the command is setup execute the setup function
            setup;;

        #if the command is nosecrets check and execute the called function
        "nosecrets" )
            #run the commands for nosecrets
            setup
            case $command2 in
            "--install" )
                #if the command is install run the install function
                install_package "nosecrets";;
            "--uninstall" )
                #if the command is uninstall run the uninstall function
                uninstall_nosecrets;;
            "--test" )
                #if the command is test run the test function
                #check if nosecrets is installed
                if [[ ! -d $INSTALL_DIR/nosecrets ]]; then
                    echo "nosecrets is not installed"
                    handle_error "nosecrets is not installed. Install nosecrets using: ./webserver_assignment.sh nosecrets --install"
                else
                    #if nosecrets is installed run the test
                    test_nosecrets
                fi;;
            esac;;

        # do the same for pywebserver as for nosecrets
        "pywebserver" )
            setup
            case $command2 in
            "--install" )
                install_package "pywebserver";;
            "--uninstall" )
                uninstall_pywebserver;;
            "--test" )
                if [[ ! -d $INSTALL_DIR/pywebserver ]]; then
                    echo "pywebserver is not installed"
                    handle_error "pywebserver is not installed. Install pywebserver using: ./webserver_assignment.sh pywebserver --install"
                else
                    test_pywebserver
                fi;;

            esac;;
        
        #incase it is remove run the remove function
        "remove" )
            remove;;
    esac

}

# Pass commandline arguments to function main
main "$@"
