#!/bin/bash

# Constants
LOG_FILE="manage_users.log"
USER_FILE="usernames.csv"
INACTIVE_DAYS_THRESHOLD=90  # Adjust as per your organization's policy

# Function to create user and set permissions
create_user() {
    local username=$1
    local group=$2
    local permission=$3

    # Create user with specified group
    sudo groupadd -f $group  # Add group if not exists
    sudo useradd -m -s /bin/bash -g $group $username

    # Set home directory permissions
    sudo chmod $permission /home/$username

    # Log creation
    echo "$(date '+%Y-%m-%d %H:%M:%S') - User $username created with group $group and permissions $permission" >> $LOG_FILE

    # Create projects directory and README.md file
    sudo -u $username mkdir /home/$username/projects
    echo "Welcome, $username! some intro message here." | sudo -u $username tee /home/$username/projects/README.md > /dev/null
}

# Function to handle interactive mode
interactive_mode() {
    echo "Interactive mode:"
    echo "1. Add user"
    echo "2. Delete user"
    echo "3. Modify user permissions"
    read -p "Choose an action (1/2/3): " action

    case $action in
        1)
            read -p "Enter username: " username
            read -p "Enter group: " group
            read -p "Enter permissions (e.g., 755): " permission
            create_user $username $group $permission
            ;;
        2)
            read -p "Enter username to delete: " username
            sudo userdel -r $username
            echo "$(date '+%Y-%m-%d %H:%M:%S') - User $username deleted" >> $LOG_FILE
            ;;
        3)
            read -p "Enter username to modify permissions: " username
            read -p "Enter new permissions (e.g., 755): " permission
            sudo chmod $permission /home/$username
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Permissions changed for $username to $permission" >> $LOG_FILE
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Main script

# Ensure log file exists
touch $LOG_FILE

# Read usernames.csv file
while IFS=',' read -r username group permission; do
    create_user $username $group $permission
done < $USER_FILE

# Interactive mode prompt
echo "Do you want to enter interactive mode? (yes/no)"
read answer
if [ "$answer" = "yes" ]; then
    interactive_mode
fi

# Automated user cleanup (sample implementation)
inactive_users=$(lastlog -b $INACTIVE_DAYS_THRESHOLD | grep -v "Never" | grep -v "Username" | awk '{print $1}')
for user in $inactive_users; do
    sudo userdel -r $user
    echo "$(date '+%Y-%m-%d %H:%M:%S') - User $user deleted due to inactivity" >> $LOG_FILE
done
