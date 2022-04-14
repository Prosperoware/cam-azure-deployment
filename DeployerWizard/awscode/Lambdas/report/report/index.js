

var AWS = require("aws-sdk");
var uuid = require("uuid")

if (process.env.RUNNINGLOCALLY === 'true') {
  var credentials = new AWS.SharedIniFileCredentials({ profile: 'dev' });
  AWS.config.credentials = credentials;
}

var documentClient = new AWS.DynamoDB.DocumentClient({ 'region': process.env.AWSREGION });
exports.handler = async (event) => {

  console.log(JSON.stringify(event));
  let body = JSON.parse(event.body);


  try {
    console.log('1')
    var params = {
      TableName: process.env.TABLE_LOGS,
      IndexName: 'tenantid-index',
      KeyConditionExpression: 'tenantid = :hkey',
      ExpressionAttributeValues: {
        ':hkey': body.tenantid,
      }
    };

    console.log('2')
    let espera = await documentClient.query(params).promise();
    console.log('3')
    const de = new Date().getTime()
    const today = new Date().toJSON();
    if (espera.Count > 0) {
      console.log('4')

      for (let index = 0; index < espera.Items.length; index++) {
        const element = espera.Items[index];
        if (element.azurestatus === undefined) {
          element.azurestatus = body.status;
          element.azuredate = today;
          var paramput = {
            TableName: process.env.TABLE_LOGS,
            Item: element
          }

          let espera = await documentClient.put(paramput).promise();
        }

      }

    }
    else {

      console.log('5 - first deploy');
      /// get customer info

      try {

        var params = {
          TableName: process.env.DYNAMOTABLE,
          KeyConditionExpression: 'prosperoTenantid  = :hkey',
          ExpressionAttributeValues: {
            ':hkey': body.tenantid,
          }
        };

        let subscriptioninfo = await documentClient.query(params).promise();
        if (subscriptioninfo.Count === 1) { //it should already exists en susbscibers table
          const de = new Date().getTime()
          const today = new Date().toJSON();
          var log = {
            Logid: uuid.v1(),
            tenantid: body.tenantid,
            version: 'FirstDeploy',
            url:subscriptioninfo.Items[0].url,
            reponame:subscriptioninfo.Items[0].reponame,
            projectname: subscriptioninfo.Items[0].projectName,
            date: de,
            datef: today,
            status: 'FirstDeploy'
          }

          log.azurestatus = body.status;
          log.azuredate = today;
          var paramput = {
            TableName: process.env.TABLE_LOGS,
            Item: log
          }
          try {
            
            let espera = await documentClient.put(paramput).promise();
          } catch (error) {
            return ErrorResponse({ mesage: 'Could not save the log error 3232' }, 500);
          }

        }

      } catch (error) {
        console.log('Failed when looking for subscripton info');
        console.log(JSON.stringify(error))
        return ErrorResponse({ mesage: 'Could not find subscription' }, 500);
      }

      ///

    }

    return OkResponse();
  }
  catch (error) {
    console.log('Error al intentar leer el s3' + error);
    return ErrorResponse({ mesage: 'Error' }, 500);
  }


}


var headers = {
  "Content-Type": "application/json"
}

/**
 * Create a success response
 * @param {Number} statusCode http status code
 * @param {object} body response body
 * @returns {object} Success response
 */
function OkResponse(body = {}, statusCode = 200) {

  return {
    headers: headers,
    statusCode: statusCode,
    body: JSON.stringify(body)
  }
}
/**
 * Create Error response object
 * @param {Number} statusCode http status code
 * @param {object} message error description
 * @returns {object} Error responses
 */
function ErrorResponse(message, statusCode) {
  return {
    headers: headers,
    statusCode: statusCode,
    body: JSON.stringify({
      message: message
    })
  }
}

