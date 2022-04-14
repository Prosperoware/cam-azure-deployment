process.env.RUNNINGLOCALLY=true;
process.env.AWSREGION = 'us-east-1'
process.env.DYNAMOTABLE = 'CFAzureDeployerLog';

var lambda = require("./dashboard/index.js");
arranca();

async function arranca(){

    let res = lambda.handler().then((data) => {
        console.log(JSON.stringify(data));
    });
}