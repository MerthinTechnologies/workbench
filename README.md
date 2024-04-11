# workbench

The script  is used to synchronize GitHub & Linear and setup a baseline to start working.
As a result, you'll get a drafted PR and a referenced branch name in both systems

## Installation and Usage Requisites

1- Install github CLI  (https://github.com/cli/cli?tab=readme-ov-file#installation)

2- Ensure you have jq installed 

3- Create a Personal Github Token

4- Create a Linear's Personal API token

## Installation
### Install the latest version
curl -sL https://raw.githubusercontent.com/MerthinTechnologies/workbench/master/workbench.install.sh | sh

## Usage
Usage: workbench [option]
Options:
  --configure   Configure GitHub and Linear Authentication
  --version     Display the version of the script.
  --help        Display this help message.

Use it without options to follow the intended startup procedure.