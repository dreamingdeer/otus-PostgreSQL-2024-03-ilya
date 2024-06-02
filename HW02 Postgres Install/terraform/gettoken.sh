#!/bin/sh
if [[ $SHELL =~ "fish" ]]; then
    set -x TF_VAR_iam_token $(yc iam create-token)
else 
    # export TF_VAR_iam_token=$(yc iam create-token)
fi
