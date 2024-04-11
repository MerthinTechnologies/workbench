get_git_branch() {
    local issue_id=$1
    local api_url='https://api.linear.app/graphql'
    local auth_token=$2

    local json_payload=$(cat <<EOF
{
  "query": "query GetGitBranch(\$issueId: String!) {\\n  issue(id: \$issueId) {\\n    branchName\\n  }\\n}",
  "variables": {
    "issueId": "${issue_id}"
  }
}
EOF
    )

    curl -s --location "${api_url}" \
         --header "Authorization: ${auth_token}" \
         --header 'Content-Type: application/json' \
         --data "${json_payload}" | jq ".data.issue.branchName" | tr -d '"'
}

get_issues() {
    local status=$1
    local auth_token=$2
    local api_url='https://api.linear.app/graphql'

    local json_payload=$(cat <<EOF
{
  "query": "query GetViewerTodoIssues {\\n  viewer {\\n    assignedIssues(filter: { state: { name: { eq: \\"${status}\\" } } }) {\\n      nodes {\\n        identifier\\n        title\\n        state {\\n          name\\n        }\\n      }\\n    }\\n  }\\n}"
}
EOF
    )

    curl -s --location "${api_url}" \
         --header "Authorization: ${auth_token}" \
         --header 'Content-Type: application/json' \
         --data "${json_payload}" | jq '[.data.viewer.assignedIssues.nodes[] | {identifier: .identifier, title: .title, status: .state.name}]'
}

get_title_by_identifier() {
    local identifier=$1
    local json=$2
    echo $json | jq -r --arg id "$identifier" '.[] | select(.identifier == $id) | .title'
}

display_and_select_issue() {
    local json=$1

    identifiers=()
    local counter=1
    echo "These are the current tasks assigned to you (you should move any task to TODO or IN PROGRESS status in order to appear here)"
    echo ""

    echo "In Progress:"
    while IFS= read -r line; do
        echo "$counter- $line"
        identifier=$(echo "$line" | awk '{print $1}')
        identifiers+=("$identifier")
        ((counter++))
    done < <(echo "$json" | jq -r '.[] | select(.status == "In Progress") | .identifier + " -> \"" + .title + "\""')

    echo ""
    echo "Todo:"
    while IFS= read -r line; do
        echo "$counter- $line"
        identifier=$(echo "$line" | awk '{print $1}')
        identifiers+=("$identifier")
        ((counter++))
    done < <(echo "$json" | jq -r '.[] | select(.status == "Todo") | .identifier + " -> \"" + .title + "\""')
    echo ""

    read -p "Select the Issue number associated with the task you want to work with: " issue_num

    if [[ ! "$issue_num" =~ ^[0-9]+$ ]] || [ "$issue_num" -lt 1 ] || [ "$issue_num" -gt "${#identifiers[@]}" ]; then
        echo "Invalid selection. Please enter a number between 1 and ${#identifiers[@]}."
        return 1
    fi

    local selected_identifier=${identifiers[$((issue_num-1))]}
    
    echo "$selected_identifier" > /tmp/wbselection
}

check_file() {
    local file=$1

    if [ -z "$file" ]; then
        echo "No file name provided."
        exit 1
    fi

    if [ ! -f "$file" ]; then
        echo "The file '$file' does not exist. Please run the command with the --configure option"
        exit 1
    fi

    if [ ! -s "$file" ]; then
        echo "The file '$file' exists but is empty. Please run the command with the --configure option"
        exit 1
    fi
    echo $(cat $file)
}

select_remote_branch() {
    git fetch --prune --all

    IFS=$'\n' read -r -d '' -a branches <<< "$(git branch -r|grep -v 'origin/HEAD')"

    if [ ${#branches[@]} -eq 0 ]; then
        echo "No remote branches found."
        return
    fi

    echo "Select a remote branch:"
    for i in "${!branches[@]}"; do
        echo "$((i + 1)). ${branches[i]}"
    done

    echo ""
    read -p "Enter the number of the branch you want to use as PR base: " selection

    if [ -z "$selection" ] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#branches[@]}" ]; then
        echo "Invalid selection."
        return
    fi

    selected_branch_index=$((selection - 1))

    selected_branch=$(echo "${branches[$selected_branch_index]}" | sed 's/^[^\/]*\///')

    echo "$selected_branch" > /tmp/prbranchselection
}

get_remote_repo_url() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "You are not inside a Git repository."
        return 1
    fi

    remote_url=$(git remote get-url origin 2>/dev/null)

    if [ -z "$remote_url" ]; then
        echo "Remote URL for 'origin' not found."
        return 1
    else
        echo "You're currently positioned to work over with a local copy of this repository:"
        echo "  $remote_url"
        echo ""
        read -p "Press ENTER to confirm and continue, or Abort using CTRL/CMD-C"
    fi
}

check_uncommitted_changes() {
    echo "You're currently checked out in this branch:"
    echo "  $(git rev-parse --abbrev-ref HEAD)"
    if ! git diff --quiet || ! git diff --staged --quiet; then
        echo "There are uncommitted changes."
        read -p "Do you want to stash your changes? [Y/n]: " answer
        answer=${answer:-Y}  

        case $answer in
            [Yy]* | "" )
                git stash
                echo "Changes stashed."
                return 0
                ;;
            [Nn]* )
                echo "Operation aborted."
                return 1
                ;;
            * )
                echo "Invalid input. Operation aborted."
                return 1
                ;;
        esac
    else
        echo "No uncommitted changes."
        return 0
    fi
}

request_and_store_tokens() {
    CFGDIR="$HOME/.config/workbench"
    mkdir -p "$CFGDIR"

    echo "Enter your GitHub Personal Token:"
    read -s -p "GitHub Token: " gitToken
    echo "$gitToken" > "$CFGDIR/git.token"
    chmod 600 "$CFGDIR/git.token"
    echo ""

    echo "Enter your Linear Personal API Token:"
    read -s -p "Linear Token: " linearToken
    echo "$linearToken" > "$CFGDIR/linear.token"

    chmod 600 "$CFGDIR/linear.token"
    echo ""
    echo "Tokens have been stored securely. Configuration complete"
}

display_help() {
    local scriptName=$(basename "$0")
    echo "The script $script_name is used to syncronize GitHub & Linear and setup a baseline to start working."
    echo "As a result, you'll get a drafted PR and a referenced branch name in both systems"
    echo ""
    echo "Usage: $scriptName [option]"
    echo "Options:"
    echo "  --configure   Configure GitHub and Linear Authentication"
    echo "  --version     Display the version of the script."
    echo "  --help        Display this help message."
    echo ""
    echo "Use it without options to follow the intended startup procedure."
}
