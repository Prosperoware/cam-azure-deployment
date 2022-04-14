#!/bin/bash 

#invocar using ./update_CloudFormation.sh env update/create 
case $1 in
  "dev")
    echo Updating Dev
    stackname=AzureDeployerDev
    s3path=pros-azuredeployer-templates-dev
    urlpath=$s3path.s3.amazonaws.com
    region=us-east-1
    profile=dev;
    ApiGWStage=dev
    ;;
  "devxher")
    echo Updating Dev
    stackname=AzureDeployerDev
    s3path=azuredeployer-templates-dev
    urlpath=$s3path.s3.amazonaws.com
    region=us-east-1
    profile=xher;
    ApiGWStage=dev
    ;;
esac     

echo $ApiGWStage - stage
aws s3 cp AzureDeployer.yaml s3://$s3path/AzureDeployer.yaml --profile $profile
aws cloudformation $2-stack \
    --stack-name $stackname \
    --template-url https://$urlpath/AzureDeployer.yaml \
    --parameters ParameterKey=ApiGwStage,ParameterValue=$ApiGWStage \
    --capabilities CAPABILITY_NAMED_IAM --region $region --profile $profile


    #https://azuredeployer-templates-dev.s3.amazonaws.com/Contrato+.docx