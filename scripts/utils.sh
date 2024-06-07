#!/bin/bash

# Define ANSI escape codes for syntax highlighting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
ORANGE='\033[0;91m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# define global variable to hold return value
#RET_VAL=""

#######################################################
# @brief Echoes text with syntax highlighting.
#
# This function echoes the provided text with syntax highlighting using ANSI escape codes.
#
# @param color The ANSI escape code representing the desired text color and style.
# @param text The text to be displayed with syntax highlighting.
#
# Example usage: echo_with_syntax_highlighting <color_code> <text>
# echo_with_syntax_highlighting "$RED" "This text is in red."
# echo_with_syntax_highlighting "$GREEN$BOLD" "This text is bold and green."
# echo_with_syntax_highlighting "$BOLD$RED" "This text is bold and red."
# echo_with_syntax_highlighting "$BOLD$GREEN" "This text is bold and green."
echo_with_syntax_highlighting() {
	local color="$1"
	local text="$2"
	echo -e "${color}${text}${RESET}"
}

#######################################################
# @brief Prints info with the desired text
#
# @param text The text to be displayed.
print_info() {
	#local text="$1"
	echo_with_syntax_highlighting "$YELLOW$BOLD" "$1"
}

#######################################################
# @brief Prints error with the desired text
#
# @param text The text to be displayed.
print_error() {
	#local text="$1"
	echo_with_syntax_highlighting "$RED$BOLD" "$1"
}

# # Obtain additional utility functions
# Function to source helper scripts
source_helper() {
	local help_script=$1
	if ! source "$(realpath "$help_script")"; then
		echo "Error: Could not find or source helper script $help_script"
		echo "Aborting..."
		#        return 1  # Use return instead of exit
		exit 1
	fi
	echo "Sourced: $help_script"
}

#######################################################
# @brief Run a make command and handle the result.
#
# This function executes a given make command and handles the result.
# If the make command succeeds, it checks if there was nothing to be done for the target.
# If the make command fails, an error message is printed, and the script exits.
#
# @param make_cmd The make command to be executed.
#
run_make_cmd() {
	# Execute the provided make command
	echo "$1"
	eval "$1"

	# Check the exit status of the make command
	if [ $? -eq 0 ]; then
		# If the output indicates "Nothing to be done for 'all'", proceed without printing the command
		if echo "$1" | grep -q "Nothing to be done for 'all'"; then
			echo "Nothing to be done. Proceeding..."
		else
			echo "$1"
		fi
	else
		# If the make command fails, print an error message and exit
		print_error "Make: Aborting..."
		exit 1
	fi
}

#######################################################
# @brief Run a make command and handle the result.
# @brief Clone a Git repository if the directory doesn't exist.
#
# This function clones a Git repository if the specified directory doesn't exist.
# It displays a message and runs a given command (the Git clone command) if the directory is not found.
#
# @param repo_dir The target directory where the repository should be cloned.
# @param msg A message to be displayed if the directory doesn't exist.
# @param cmd The command (Git clone command) to be executed if the directory doesn't exist.
# Example usage:
# clone_repo "my_repository" "Cloning repository..." "git clone https://github.com/example/repository.git"
#
clone_repo() {
	# local repo_dir_=$1
	# local msg_=$2
	# local cmd_=$3
	if [ ! -d "$1" ]; then
		echo "$2" # Display the provided message
		echo "$3"
		eval "$3" # Execute the provided command (e.g., Git clone command)
	fi
}

#######################################################
# @brief Run a Bash command and handle the result.
#
# This function executes a given Bash command and handles the result.
# If the command succeeds, it prints a success message.
# If the command fails, it prints an error message and exits the script.
#
# @param cmd The Bash command to be executed.
# @param succ_msg The success message to be printed if the command succeeds.
# @param err_msg The error message to be printed if the command fails.
#
# Example usage:
# run_bash_cmd "ls -l" "Command executed successfully." "Error: Command failed."
run_bash_cmd() {
	#local cmd_=$1
	#local succ_msg_=$2
	#local err_msg_=$3
	eval "$1"

	if [ $? -eq 0 ]; then
		echo "$2" # Print success message
	else
		echo "$3" # Print error message
		exit 1
	fi
}

##########################################
# @brief Create a directory if it doesn't exist.
#
# This function creates a directory if the specified directory doesn't exist.
# It also prints a message if the directory is created.
#
# @param dir The directory path to be created.
#
# Example usage:
# create_dir "my_directory"
create_dir() {
	#echo "$1"  # Display the provided directory path

	if [ ! -d "$1" ]; then
		mkdir -p "$1" && echo "Creating dir: $1"
	fi
}

##########################################
## @function save_array_to_file
## @brief Saves the contents of an array to a file.
##
## This function accepts an array and saves its contents to a file.
##
## @param array_name The name of the array to be saved.
## @param output_file The file where the array contents will be saved.
##
## Example usage:
## ```
## my_array=("Value1" "Value2" "Value3")
## save_array_to_file my_array output.txt
## ```
##########################################
save_array_to_file() {
	local array_name="$1[@]"
	local output_file="$2"

	# Concatenate array elements into a single variable with spaces
	local concatenated_contents="${!array_name}"

	# Save the concatenated contents to the output file
	echo "$1=($concatenated_contents)" >>"$output_file"
}

##########################################
# @brief Save a variable to a file.
#
# This function appends a given variable and its value to a specified file.
#
# @param var_name The name of the variable to be saved.
# @param var_val The value of the variable to be saved.
# @param out_file The path of the file to which the variable is saved.
#
# Example usage:
# save_var_to_file "my_var" "my_value" "output.txt"
save_var_to_file() {
	#    local var_name="$1"
	#    local var_val="$2"
	#    local out_file="$3"
	echo "$1=\"$2"\" >>"$3"
}

##########################################
# @brief Get user choice from a list of options.
#
# This function presents a list of options to the user, prompts them to choose an option,
# and returns the index of the chosen option.
#
# @param options_array An array containing the available options.
# @return The index of the chosen option. Returns 255 if the choice is invalid.
#
# Example usage:
# options=("Option 1" "Option 2" "Option 3")
# get_user_choice "${options[@]}"
get_user_choice() {
	local options_array=("$@")
	local num_options=${#options_array[@]}

	# Print the options to the user
	echo "Please choose an option:"
	for ((i = 0; i < num_options; i++)); do
		echo "$((i + 1)). ${options_array[i]}"
	done

	read -rp "Enter the option number: " user_choice

	# Trim leading and trailing whitespace
	# The conditional statement checks two conditions:
	# 1. -n "$user_choice" ensures that the input is not empty.
	# 2. "$user_choice" =~ ^[0-9]+$ checks if the input contains only numeric
	# characters. This helps to ensure that the user enters a valid numeric choice.
	user_choice=${user_choice##*( )}
	user_choice=${user_choice%%*( )}

	if [[ -n "$user_choice" && "$user_choice" =~ ^[0-9]+$ ]]; then
		local index=$((user_choice - 1))
		if [ "$index" -ge 0 ] && [ "$index" -lt "$num_options" ]; then
			return $index
		fi
	fi

	return 255 # Invalid choice (returning a non-zero value for error)
}

##
# @brief Checks if a variable is empty.
#
# This function checks if the provided variable is empty.
#
# @param variable The variable to be checked.
# @return 0 if the variable is empty, 1 otherwise.
is_var_empty() {
	local var="$1"

	echo "$var"

	if [ -z "$var" ]; then
		echo "The variable is empty."
	else
		echo "The variable is not empty."
	fi

	[ -z "$var" ] # returning the result
}

########################################################
# @brief Check dependencies
#
check_deps() {
	local deps="$1"
	print_info "Checking dependencies (assuming Ubuntu-based distros)"
	echo ">> Packages to check: $deps"

	IFS=' ' read -ra package_array <<<"$deps"

	echo ">> Updating the system first..."
	sudo apt update

	for package in "${package_array[@]}"; do
		if dpkg -l | grep -q $package; then
			echo "$package is already installed."
		else
			sudo apt-get install -y $package
		fi
	done
}

######################################################
setup_env() {
	# Retrieve saved variables
	ENV_FILE="$BASH_MAIN/scripts/env.txt"
	source_helper "$ENV_FILE"

	# changing to run directory
	ignore_error=false
	RUN_DIR="$BASH_MAIN"
	cd "$RUN_DIR" || (echo "Missing dir: $RUN_DIR" && exit 1)

	ignore_error=true

	# check var is empty
	[ -z "$PLATFORM" ] && echo "$PLATFORM: empty... Aborting" && exit
	[ -z "$DEMO" ] && echo "$DEMO: empty... Aborting" && exit
	[ -z "$ARCH" ] && echo "$ARCH: empty... Aborting" && exit

	export CROSS_COMPILE="$CROSS_COMPILE"
	export PLATFORM="$PLATFORM"
	export ARCH="$ARCH"
	export DEMO="$DEMO"
	export BAO_DEMOS="$BASH_MAIN"
	export BAO_DEMOS_WRKDIR=$BAO_DEMOS/wrkdir
	export BAO_DEMOS_WRKDIR_SRC=$BAO_DEMOS_WRKDIR/srcs
	export BAO_DEMOS_WRKDIR_BIN=$BAO_DEMOS_WRKDIR/bin
	export BAO_DEMOS_WRKDIR_PLAT=$BAO_DEMOS_WRKDIR/imgs/$PLATFORM
	export BAO_DEMOS_WRKDIR_IMGS=$BAO_DEMOS_WRKDIR_PLAT/$DEMO

	print_env
}

print_env() {
	print_info "======================================"
	print_info "............... Environment info ................."
	print_info "CROSS_COMPILE: $CROSS_COMPILE"
	print_info "PLATFORM: $PLATFORM"
	print_info "DEMO: $DEMO"
	print_info "ARCH: $ARCH"
	print_info "BUILD_TYPE: $BUILD_TYPE"
	print_info "RUN_DIR: $RUN_DIR"
	print_info "BAO_DEMOS             = $BAO_DEMOS"
	print_info "BAO_DEMOS_WRKDIR      = $BAO_DEMOS_WRKDIR"
	print_info "BAO_DEMOS_WRKDIR_SRC  = $BAO_DEMOS_WRKDIR_SRC"
	print_info "BAO_DEMOS_WRKDIR_BIN  = $BAO_DEMOS_WRKDIR_BIN"
	print_info "BAO_DEMOS_WRKDIR_PLAT = $BAO_DEMOS_WRKDIR_PLAT"
	print_info "BAO_DEMOS_WRKDIR_IMGS = $BAO_DEMOS_WRKDIR_IMGS"
	print_info "======================================"
}

####################################################
patch_file() {
	local file="$1"
	local line_number="$2"
	local text_to_insert="$3"

	#file="./tmp/optee_os/core/arch/arm/kernel/link.mk"
	#line_number=20
	#text_to_insert="link-ldflags += --no-warn-rwx-segments\n"
	# Use 'sed' to replace the line with the new content

	print_info ">> Patching file $file"

	sed -i "${line_number}s/.*/$text_to_insert/" "$file"
}

########################################################
# @brief Custom error handler function.
#
# This function is used to handle errors in the script execution.
# It prints an error message with the exit code and can either exit the script
# or continue execution based on the value of the $ignore_error variable.
#
# @global ignore_error If set to "false", the script will exit on error. If set to any other value, errors will be ignored.
#
error_handler() {
	local error_code="$?"
	local function_name="${FUNCNAME[-2]}"
	local line_number="${BASH_LINENO[-2]}"
	local source_file="${BASH_SOURCE[-2]}"

	if [ "$ignore_error" = "false" ]; then
		print_error "ERROR ($error_code): $source_file (line $line_number, function $function_name)"
		exit "$error_code"
	fi

	# Otherwise, errors are ignored
}

### Handle errors globally
# Global variable to control error ignoring
ignore_error=false

# Set the custom error handler with 'trap'
trap 'error_handler' ERR
