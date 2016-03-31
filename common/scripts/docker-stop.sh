#!/bin/bash
# ------------------------------------------------------------------------
#
# Copyright 2016 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

# ------------------------------------------------------------------------
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}/base.sh"

while getopts :n: FLAG; do
    case $FLAG in
        n)
            product_name=$OPTARG
            ;;
    esac
done

read -r -a running_container_ids <<< $(docker ps | grep $product_name | awk '{print $1}')
if [ "${#running_container_ids[@]}" -eq 0 ]; then
    echo "No running containers for $(echo $product_name | awk '{print toupper($0)}') was found."
else
    echoBold "Found ${#running_container_ids[@]} containers matching $(echo $product_name | awk '{print toupper($0)}')"
    for running_container_id in "${running_container_ids[@]}"
    do
        running_container_info=$(docker ps -f "id=${running_container_id}" | awk -F '[[:space:]][[:space:]]+' '{if (NR!=1) print $NF,"-",$1,"Started", $4, "from image", $2}')
        echo -n "${running_container_info}"
        askBold " - Terminate? (y/n): "
        read -r terminate_v
        if [ "$terminate_v" == "y" ]; then
            {
                docker kill $running_container_id > /dev/null 2>&1 && echoSuccess "$(echo $running_container_info | awk '{print $1,"(",$3,")"}') was terminated."
            } || {
                echoError "Couldn't terminate container $(echo $running_container_info | awk '{print $1,"(",$3,")"}')."
            }
        fi
    done
fi

echo
askBold "Clean already exited containers? (y/n): "
read -r clean_exited_v
if [ "$clean_exited_v" == "y" ]; then
    {
        echo "Cleaning..." && docker rm $(docker ps -q -f status=exited) > /dev/null 2>&1 && echoSuccess "Cleaned all exited containers."
    } || {
        echoError "Could not clean one or more exited containers."
    }

fi
