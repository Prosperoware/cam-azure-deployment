var AWS = require("aws-sdk");
if (process.env.RUNNINGLOCALLY === 'true') {
    var credentials = new AWS.SharedIniFileCredentials({ profile: 'dev' });
    AWS.config.credentials = credentials;
}
exports.handler = async (event) => {
   

    try {
        var documentClient = new AWS.DynamoDB.DocumentClient({ 'region': process.env.AWSREGION });
        var params = {
            TableName: process.env.DYNAMOTABLE,
        };

        espera = await documentClient.scan(params).promise();
        return OkResponse(espera.Items);

    } catch (error) {
        return ErrorResponse('un expected error', 500);
    }


};
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
