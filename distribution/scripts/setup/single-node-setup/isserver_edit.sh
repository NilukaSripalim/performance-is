#!/bin/bash -e
# Copyright (c) 2019, WSO2 Inc. (http://wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
# ----------------------------------------------------------------------------
# edit is server script.
# ----------------------------------------------------------------------------

function usage() {
    echo ""
    echo "Usage: "
    echo "$0 -l <RDS_IP>"
    echo ""
    echo "-l: The ip address of RDS"
    echo "-h: Display this help and exit."
    echo ""
}

while getopts "l:h" opts; do
    case $opts in
    l)
        db_instance_ip=${OPTARG}
        ;;
    h)
        usage
        exit 0
        ;;
    \?)
        usage
        exit 1
        ;;
    esac
done

if [[ -z $db_instance_ip ]]; then
    echo "Please provide the db instance ip address."
    exit 1
fi

echo "unzipping is server"
unzip -q wso2is.zip

echo ""
echo "changing server name"
mv wso2is-* wso2is

sudo chown -R ubuntu:ubuntu wso2is

echo "changing permission for mysql connector"

chmod 644 mysql-connector-java-5.1.47.jar

carbon_home=$(realpath ~/wso2is)

echo ""
echo "Adding mysql connector to the pack..."
echo "============================================"
cp mysql-connector-java-5.1.47.jar "$carbon_home"/repository/components/lib/mysql-connector-java-5.1.47.jar

echo ""
echo "Adding deployment toml file to the pack..."
echo "============================================"
cp setup/deployment.toml "$carbon_home"/repository/conf/deployment.toml

echo ""
echo "Applying basic parameter changes..."
echo "============================================"
sed -i 's/JVM_MEM_OPTS="-Xms256m -Xmx1024m"/JVM_MEM_OPTS="-Xms2g -Xmx2g"/g' "$carbon_home"/bin/wso2server.sh || echo "Editing wso2server.sh file failed!"
sed -i "s|jdbc:mysql://wso2isdbinstance2.cd3cwezibdu8.us-east-1.rds.amazonaws.com|jdbc:mysql://$db_instance_ip|g" \
"$carbon_home"/repository/conf/deployment.toml || echo "Editing deployment.toml file failed!"

echo ""
echo "Creating databases in RDS..."
echo "============================================"
mysql -h "$db_instance_ip" -u wso2carbon -pwso2carbon < createDB.sql

echo ""
echo "Starting WSO2 IS server..."
echo "============================================"
./wso2is/bin/wso2server.sh start
sleep 100s
