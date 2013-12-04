const SLICE_ENCODED_VALUE = 7;
const NEWLINE = "\n";

queryParams <- [{ name = "timestamp", value= time()  }, { name = "apikey", value= "apiKeyToLookupDevice" }]; 

function sortByName(a,b) {
  if(a.name > b.name) 
    return 1;
  else if(a.name < b.name) 
    return -1;
  return 0;
}

function getSignedUrl(queryParameters, method, host, path, secretKey){
  local queryString = getQueryString(queryParameters);
  local signature = getSignedRequest(queryString, method, host, path, secretKey);
  local encodedSignature = getEncodedValue(signature);
  server.log("encodedSignature:" + encodedSignature);
  local endpoint = "https://" + host + path;
  local signedUrl = endpoint + "?" + queryString + "&signature=" + encodedSignature;
  server.log("signedUrl:" + signedUrl);
  return signedUrl;
}

function getSignedRequest(queryString, method, host, path, secretKey){
  // http://docs.aws.amazon.com/AmazonSimpleDB/latest/DeveloperGuide/HMACAuth.html

  /* Explanation of different request parameters used in signing
  
  StringToSign = HTTPVerb + "\n" +
                 ValueOfHostHeaderInLowercase + "\n" +
                 HTTPRequestURI + "\n" +
                 CanonicalizedQueryString <from the preceding step>
  */
  local encodeRequest = method + NEWLINE + host + NEWLINE + path + NEWLINE + queryString;
  server.log("encodeRequest:" + encodeRequest);
  local signature = http.base64encode(http.hash.hmacsha256(encodeRequest, secretKey));
  server.log("signature:" + signature);
  return signature;
}

function getQueryString(queryParameters){
  // http://docs.aws.amazon.com/AmazonSimpleDB/latest/DeveloperGuide/HMACAuth.html
  queryParameters.sort(sortByName);
  local queryString = "";
  local parameterCount = 0;
  foreach(queryParam in queryParameters) {
    local parameterName = queryParam.name;
    local parameterValue = queryParam.value;
    queryString += parameterName + "=" + parameterValue;
    if (parameterCount < queryParameters.len() - 1) {
      queryString += "&";
    }
    parameterCount++;
  }
  server.log("queryString:" + queryString);
  return queryString;
}

function getEncodedValue(valueForEncoding) {
  local tableForEncoding = { encode = valueForEncoding };
  local encodedValue = http.urlencode(tableForEncoding);
  return encodedValue.slice(SLICE_ENCODED_VALUE, encodedValue.len());
}

getSignedUrl(queryParams, "GET", "api.foobar.com", "/1/person/get_by_username", "3dd2f69f-2657-46d6-adbb-826a0546017b");
