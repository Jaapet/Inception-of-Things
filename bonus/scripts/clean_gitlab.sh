#!/bin/bash

echo -n "[1/2] Deleting GitLab namespace... "
if sudo kubectl delete namespace gitlab > /dev/null 2>&1; then
    echo "OK"
else
    echo "OK | (Not found)"
fi

echo -n "[2/2] Stopping port-forward... "
if sudo pkill -f "kubectl port-forward.*gitlab" > /dev/null 2>&1; then
    echo "OK"
else
    echo "OK | (Not running)"
fi

echo "GitLab cleaned!"
