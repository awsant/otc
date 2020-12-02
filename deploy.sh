#!/bin/bash
# OTC POC
# Create CFN Stack for IAM, VPC, EKS Cluster, Worker Nodes and CI/CD 


##################################### Functions Definitions


function aws_create_stack() {
  if [ "$#" -le "1" ]; then echo "error: aws_create_stack Stack Name & Template are Required"; exit 1; fi

  local STACK_NAME=$1
  local TEMPLATE_FILE=$2
  local PARAMS=$3
  
  local STACK_CREATE_ID=($(eval "aws " $PROFILE_PARAM " " $REGION_PARAM " cloudformation create-stack --stack-name " $STACK_NAME " --template-body " $TEMPLATE_FILE " " $PARAMS " --query 'StackId' --output text"))
  
  if [[ -z "$STACK_CREATE_ID" ]] ; then echo "$STACK_NAME Create Failed"; exit 1; fi
  echo "Creating $STACK_NAME : $STACK_CREATE_ID"
}

function aws_wait_create_stack() {
  if [ "$#" -le "0" ]; then echo "error: aws_create_stack Stack Name & Template are Required"; exit 1; fi

  local STACK_NAME=$1
  
  STACK_STATUS=$(eval "aws " $PROFILE_PARAM " " $REGION_PARAM " cloudformation wait stack-create-complete --stack-name " $STACK_NAME)
  
  if [[ $STACK_STATUS == "" ]]; then
      echo "$STACK_NAME Created"
  else
      exit 1
  fi
}


function aws_create_stack_Compute() {
  aws_create_stack $COMPUTE_STACK "file://./compute-stack.yaml" "--capabilities CAPABILITY_NAMED_IAM"
}


function aws_create_stack_Deploy() {
  aws_create_stack $DEPLOY_STACK "file://./deploy-stack.yaml" "--capabilities CAPABILITY_NAMED_IAM"
}

function aws_create_stack_DDtable() {
  aws_create_stack $DDT_STACK "file://./dynamodb.yaml" "--capabilities CAPABILITY_NAMED_IAM"
}

##################################### End Function Definitions

NARGS=$#

# extract options and their arguments into variables.
while true; do
    case "$1" in
        -p | --profile)
            PROFILE="$2"
            PROFILE_PARAM="--profile $PROFILE"
            shift 2
            ;;
        -r | --region)
            REGION="$2";
			REGION_PARAM="--region $REGION"
            shift 2
            ;;
        --compute_stack)
            COMPUTE_STACK="$2";
            shift 2
            ;;
        --deploy_stack)
            DEPLOY_STACK="$2";
            shift 2
            ;;
        --ddt_stack)
            DDT_STACK="$2";
            shift 2
            ;;    
        --)
            break
            ;;
        *)
            break
            ;;
    esac
done

if [[ $NARGS == 0 ]] ; then echo " "; fi

if [[ -z "$COMPUTE_STACK" ]] ; then COMPUTE_STACK="otc-compute"; fi
if [[ -z "$DEPLOY_STACK" ]] ; then DEPLOY_STACK="otc-deploy"; fi
if [[ -z "$DDT_STACK" ]] ; then DDT_STACK="otc-dynamodb"; fi



echo "VPC Stack Name : $COMPUTE_STACK"
echo "EKS Stack Name : $DEPLOY_STACK"
echo "EKS Stack Name : $DDT_STACK"



#aws_create_stack_Compute
#aws_wait_create_stack $COMPUTE_STACK

##########
#aws eks --region us-west-2 update-kubeconfig --name OTC-EKS 
#sleep 10 
#kubectl apply -f ./kube-manifests/deploy-first.yml
#sleep 5m


#aws_create_stack_Deploy
#aws_wait_create_stack $DEPLOY_STACK

aws_create_stack_DDtable
aws_wait_create_stack $DDT_STACK
exit;
