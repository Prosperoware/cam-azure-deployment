
var AWS = require("aws-sdk");
if (process.env.RUNNINGLOCALLY === 'true') {
  var credentials = new AWS.SharedIniFileCredentials({ profile: 'xher' });
  AWS.config.credentials = credentials;
}



exports.handler = async (event) => {

  console.log(JSON.stringify(event));
  var token='';
  var tenantid='';
  var domain='';
  domain = event.headers.domain;
  if(event.routeKey.includes('customer')){
    console.log('Post Customer');
    tenantid = event.headers.tenantid;
    token = event.headers.authorization;
    
  }
  else{
    try {
      console.log('Report');
      let data = event.headers.authorization.split(' ');
      let buff = Buffer.from(data[1], 'base64');
      //let text =Buffer.from(data[1]).toString('ascii')
      let text = buff.toString('ascii');
      console.log(text);
      tenantid = text.split(':')[0];
      token = text.split(':')[1];
    } catch (error) {
      
    }
  }
  console.log(token);

  let res;

  var validation = await getConfirmation(tenantid,token,domain);


  if (validation) {

    res = generatePolicy('user', 'Allow', 'POST')
  }
  else {
    res = generatePolicy('user', 'Deny', 'POST')
  }
  console.log(JSON.stringify(res));
  return res;

};
// Help function to generate an IAM policy
var generatePolicy = function (principalId, effect, resource) {
  var authResponse = {};

  authResponse.principalId = principalId;
  if (effect && resource) {
    var policyDocument = {};
    policyDocument.Version = '2012-10-17';
    policyDocument.Statement = [];
    var statementOne = {};
    statementOne.Action = '*';
    statementOne.Effect = effect;
    statementOne.Resource = '*';
    policyDocument.Statement[0] = statementOne;
    authResponse.policyDocument = policyDocument;
  }

  // Optional output with custom properties of the String, Number or Boolean type.
  authResponse.context = {
    "stringKey": "stringval",
    "numberKey": 123,
    "booleanKey": true
  };
  return authResponse;
}

async function getConfirmation(prosperoTenantid,secret,domain) {

  var dynamo_table='';
  var region='';
  console.log('Domain'+domain);
  switch(domain) {
    case 'prosperowaredev.io':
      region='us-east-1';
      
      dynamo_table='prosperowaredev.io_Tenant_Subscribers';
      break;
    case 'prosperowaredev.eu':
      region='eu-west-1';
      dynamo_table='prosperowaredev.eu_Tenant_Subscribers';
      break;
    default:
      // code block
  }

  try {

    var documentClient = new AWS.DynamoDB.DocumentClient({'region': region});
    var params = {
      TableName: dynamo_table,
      KeyConditionExpression: 'tenant_id = :hkey',
      ExpressionAttributeValues: {
        ':hkey': prosperoTenantid,
      }
    };
    console.log('Call region' + region);
    console.log('Call ' + JSON.stringify(params));
    let espera = await documentClient.query(params).promise();
    console.log(espera.Count);
    if(espera.Count===1){

      if(espera.Items[0].etlConfig.clientSecret === secret){
        console.log('Authorized');
        return true;
      
      }
      else{ 
        console.log('Nof found');
        return false;
      }
    }
    else{
      return false;
    }
    
  } catch (error) {
    console.log('Error on dynamo-call '+ JSON.stringify(error));
    return false;
  }

}
