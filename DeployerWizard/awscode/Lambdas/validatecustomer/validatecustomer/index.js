


var AWS = require("aws-sdk");

if (process.env.RUNNINGLOCALLY === 'true') {
    var credentials = new AWS.SharedIniFileCredentials({ profile: 'xher' });
    AWS.config.credentials = credentials;
}
var crypto = require('crypto');
const algorithm = 'aes-256-cbc';
const secret = 'shezhuansauce';
const keyga = crypto.createHash('sha256').update(String(secret)).digest('base64');
const key = Buffer.from(keyga, 'base64')
const iv = crypto.randomBytes(16);

exports.handler = async (event) => {
    try {
        
        
        console.log(JSON.stringify(event));
        var tenantid = event.headers.tenantid;
        var token = event.headers.authorization;
        var domain = event.headers.domain;
        
        
        
        var dynamo_table='';
        var region='';
  
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
        
        
        let espera;
        var documentClient = new AWS.DynamoDB.DocumentClient({ 'region': region });
        var response = {};
        try {

            try {

                var params = {
                    TableName: dynamo_table,
                    KeyConditionExpression: 'tenant_id = :hkey',
                    ExpressionAttributeValues: {
                        ':hkey': event.headers.tenantid,
                    }
                };

                espera = await documentClient.query(params).promise();

            } catch (error) {
                console.log('File not found');
                content = '[]';
            }

            if (espera.Count === 1) { //it should already exists en susbscibers table
                console.log('Found on subscribers ');
                if(espera.Items[0].etlConfig.clientSecret === event.headers.authorization){ // secret should be the same
                    var response={
                        status:'',
                        Item:espera.Items[0].tenant_id
                    }
                    
                    
                    var params2 = {
                        TableName: process.env.AZUREDEPLOYERDYNAMOTABLE,
                        KeyConditionExpression: 'prosperoTenantid = :hkey',
                        ExpressionAttributeValues: {
                            ':hkey': event.headers.tenantid,
                        }
                    };
                    documentClient = new AWS.DynamoDB.DocumentClient({ 'region': process.env.AWSREGION });
                    let espera2 = await documentClient.query(params2).promise();
                    if(espera2.Count===0){
                    
                        response.status='Go'
                        return OkResponse(response);
                    }
                    else{
                        response.status='AzureInfoExists'
                        return OkResponse(response);
                    }
                }
                else {
                    var response={
                        status:"ErrorSecret",
                        
                    }
                    return ErrorResponse(response,400)
                }
            }
            else {
                console.log('Customer has not been inicialized')
                response.status = 'NotFound';
                response.mesage = 'customer does not exists'
                response.data = b;
                return OkResponse(response);
            }
            

        } catch (error) {
            console.log('Error in procesing the call' + error);
            return ErrorResponse({ mesage: 'Error' }, 500);
        }


    } catch (error) {
        console.log('NO SE PUDO CREAR al usuario en la db ', error);
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


function encrypt(text,key,iv) {

    // Creating Cipheriv with its parameter
    let cipher =
        crypto.createCipheriv('aes-256-cbc', Buffer.from(key), iv);

    // Updating text
    let encrypted = cipher.update(text);

    // Using concatenation
    encrypted = Buffer.concat([encrypted, cipher.final()]);

    // Returning iv and encrypted data
    return {
        iv: iv.toString('hex'),
        encryptedData: encrypted.toString('hex')
    };
}

function decrypt(text) {

    let iv = Buffer.from(text.iv, 'hex');
    let encryptedText =
        Buffer.from(text.encryptedData, 'hex');

    // Creating Decipher
    let decipher = crypto.createDecipheriv(
        'aes-256-cbc', Buffer.from(key), iv);

    // Updating encrypted text
    let decrypted = decipher.update(encryptedText);
    decrypted = Buffer.concat([decrypted, decipher.final()]);

    // returns data after decryption
    return decrypted.toString();
}