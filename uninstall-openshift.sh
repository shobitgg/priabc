#!/bin/sh

# Forward Tunnel Client

usage() {
   cat<<EOF
--namespace,    the namespace of the tunnel client installed in
--help, for help

For example:
   ./uninstall-openshift.sh --namespace tunnel
EOF
}

while true ; do
    case "$1" in
        --namespace)
            export NAMESPACE=$2
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

if [ "${NAMESPACE}" == "" ];
then
    usage
    exit 1
fi


kubectl -n ${NAMESPACE} delete deployment sre-tunnel-b8132330035a4e84-tunnel-client
kubectl -n ${NAMESPACE} delete Secret sre-tunnel-tunnel-client-secret

echo "Uninstall Tunnel Client complete."