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


function display_and_select_issue() {
    local json=$1

    identifiers=()
    local counter=1
    echo "This are the current tasks assigned to you (you should move any task to TODO or IN PROGRESS status in order to appear here)"
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

function get_store_token() {
    local system=$1
    CFGDIR=~/.config/workbench
    mkdir -p $CFGDIR
    local token_file="$CFGDIR/$system.token"

    echo "Enter your $system token:"
    read -s password

    echo $password > "$token_file"

    chmod 600 "$token_file"

    echo "Your $system token has been saved to $token_file"
}