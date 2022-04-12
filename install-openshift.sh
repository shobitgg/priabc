#!/bin/sh

# This is the Forward Tunnel Client installation script.

usage() {
   cat<<EOF
--image,                docker image name of the Secure Tunnel Client, by default It is cp.icr.io/cp/cp4mcm/secure-tunnel@sha256:33e8bd321ab87da20b514428ee0b2a9ae179aa0934fb9bcd0050041a2f4fe4ef
--image-pull-secret,    the pull secret of the image
--namespace,            the namespace of the tunnel client will be installed in
--accept-license,       If you don't set --accept-license to true, you are asked to accept the license during installation.
--help,                 for help

For example:
   ./install-openshift.sh --image cp.icr.io/cp/cp4mcm/secure-tunnel@sha256:33e8bd321ab87da20b514428ee0b2a9ae179aa0934fb9bcd0050041a2f4fe4ef --image-pull-secret integration-pull-secret --namespace tunnel --accept-license true
EOF
}


while true ; do
    case "$1" in
        --image) 
            export IMAGE=$2
            if [ "$2" == "" ]; 
            then
                usage
                exit 1
            fi
            shift 2 ;;
        --image-pull-secret)
            export IMAGE_PULL_SECRET=$2
            if [ "$2" == "" ]; 
            then
                usage
                exit 1
            fi
            shift 2 ;;
        --namespace)
            export NAMESPACE=$2
            if [ "$2" == "" ]; 
            then
                usage
                exit 1
            fi
            shift 2 ;;
        --accept-license) 
            export ACCEPT_LICENSE=$2
            if [ "$2" == "" ]; 
            then
                usage
                exit 1
            fi
            shift 2 ;;
        --help)
            usage
            exit 0 
            ;;
        -h)
            usage
            exit 0 
            ;;
        *)
            if [ "$1" != "" ]; 
            then
                usage
                exit 1
            fi
            break
            ;;
    esac
done


if [ "${IMAGE}" == "" ];
then
    export IMAGE=cp.icr.io/cp/cp4mcm/secure-tunnel@sha256:33e8bd321ab87da20b514428ee0b2a9ae179aa0934fb9bcd0050041a2f4fe4ef
fi

if [ "${NAMESPACE}" == "" ];
then
    usage
    exit 1
fi

if [ "${ACCEPT_LICENSE}" != "true" ];
then
    echo Do you accept the license agreement\(s\) found in the directory ./licenses?
    echo Please enter [ 1-to accept the agreement, 2-to decline the agreement ] : 
    read accept_license
    if [ "${accept_license}" != "1" ];
    then
        exit 0
    fi
fi

cp -n ./tunnel-client.yaml ./tunnel-client-temp.yaml
sed -i "s/integration-pull-secret/${IMAGE_PULL_SECRET}/g" ./tunnel-client-temp.yaml
export IMAGE=$(echo ${IMAGE} | sed "s/\//\\\\\//g")
sed -i "s/\${image_name}/${IMAGE}/g" ./tunnel-client-temp.yaml
sed -i "s/\${install_namespace}/${NAMESPACE}/g" ./tunnel-client-temp.yaml

kubectl -n ${NAMESPACE} delete deployment sre-tunnel-b8132330035a4e84-tunnel-client
kubectl -n ${NAMESPACE} delete Secret sre-tunnel-tunnel-client-secret

kubectl -n ${NAMESPACE} apply -f ./tunnel-client-temp.yaml
RET=$?
rm -rf ./tunnel-client-temp.yaml
if [ "${RET}" != "0" ];
then
    exit ${RET}
fi

dep="sre-tunnel-b8132330035a4e84-tunnel-client"
retries=20
while ! kubectl rollout status -w "deployment/${dep}" --namespace=${NAMESPACE}; do
    sleep 10
    retries=$((retries - 1))
    if [[ $retries == 0 ]]; then
        echo "FAIL: Failed to rollout deployloyment ${dep}, Install Tunnel Client failed."
        exit 1
    fi
    echo "retrying check rollout status for deployment ${dep}..."
done

echo "Successfully rolled out deployment \"${dep}\" in namespace \"${NAMESPACE}\""