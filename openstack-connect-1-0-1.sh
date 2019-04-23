# /bin/bash
export OS_USERNAME="dats06"
echo "Please enter your OpenStack Password: "
read -sr OS_PASSWORD_INPUT
export OS_PASSWORD="$OS_PASSWORD_INPUT"
export OS_PROJECT_NAME="dats06_project"
export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL=https://cloud.cs.hioa.no:5000/v3
