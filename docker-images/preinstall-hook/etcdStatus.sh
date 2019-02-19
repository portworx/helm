#!/bin/bash

# set -x
echo "Initializing..."
svcname=$1
etcdca=$2
etcdcert=$3
etcdkey=$4

verifyresponse() {
if [[ "$1" != 200 ]]
then
    echo "Incorrect ETCD URL provided. It is either not reachable, is incorrect or does not have the tls certificates placed in the right directory(if this is the case please validate the manner to provide certs to Portworx on docs.portworx.com)..."
    echo "Provided etcd url is not reachable or is incorrect. Exiting.." > /dev/termination-log
    exit 1
fi 
}

IFS=';' read -ra array <<< "$svcname"
for url in "${array[@]}"
do 
etcdURL=$(echo "$url" | awk -F: '{ st = index($0,":");print substr($0,st+1)}')

echo "Verifying if the provided etcd url is accessible: $etcdURL"

#Verify with certs if it is a secured etcd. 
if [[ ! -z $etcdca ]]
then
    if [[ ! -z $etcdcert ]]
        echo "Verifying connectivity to secure etcd... The certs need to be at the location $etcdca $etcdcert and $etcdkey"
        response=$(curl --write-out %{http_code} --silent --output /dev/null --cacert $etcdca --cert $etcdcert --key $etcdkey -L "$etcdURL/version" )
        echo "Response Code: $response"
        verifyresponse $response
    else
        echo "Verifying connectivity to secure etcd... The ca cert needs to be at the location $etcdca"
        response=$(curl --write-out %{http_code} --silent --output /dev/null --cacert $etcdca -L "$etcdURL/version" )
        echo "Response Code: $response"
        verifyresponse $response
    fi
else
    echo "Verifying connectivity to Insecure etcd "
    response=$(curl --write-out %{http_code} --silent --output /dev/null "$etcdURL/version")
    echo "Response Code: $response"
    verifyresponse $response
fi

done

