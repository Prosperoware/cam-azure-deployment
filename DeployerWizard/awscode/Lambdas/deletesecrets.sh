 #!/bin/bash
echo hello worldkch
output="$(aws secretsmanager list-secrets --profile xher --query 'SecretList[*].ARN' --output text)"
for i in $output; 
    do
        echo $i; 
        aws secretsmanager delete-secret --secret-id $i --recovery-window-in-days 7 --profile xher
    done