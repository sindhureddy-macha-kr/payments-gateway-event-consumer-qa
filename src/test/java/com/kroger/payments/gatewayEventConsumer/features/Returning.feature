Feature: Validate Gateway Event Consumer Returning

  Background:
    * configure ssl = true
    * def getToken = callonce read('classpath:com/kroger/payments/gatewayEventConsumer/utils/GenerateOauthToken.feature')
    * def bearerToken = 'Bearer ' + getToken.bearerToken
    * call read('classpath:com/kroger/payments/gatewayEventConsumer/utils/TestUtils.feature')

  @regression @testReturn
  Scenario Outline: Validate Returning - <Test Case>
    * def purchaseHeaders = generateHeaders(read('classpath:data/Input/Headers.json'))
    * print purchaseHeaders
    * def crossReferenceId = generateOrderId('<crossReferenceId>')
    * def purchaseRequestBody = read('classpath:data/Input/<purchaseRequest>')
    * print purchaseRequestBody
    * def purchaseTransaction = call read('classpath:com/kroger/payments/gatewayEventConsumer/utils/PreCondition.feature@purchasePreCondition') {headers : '#(purchaseHeaders)', body: '#(purchaseRequestBody)'}
    * def purchaseResponse = purchaseTransaction.purchaseResponse
    * print purchaseResponse
    * def originalTransactionId = purchaseResponse.data.id
    * def purchaseIdempotencyKey = purchaseHeaders['Idempotency-Key']
    * print purchaseIdempotencyKey
    * karate.set('purchaseIdempotencyKey',purchaseIdempotencyKey)
    * karate.set('purchaseLaneNumber',purchaseResponse.data.cardPresent.laneNumber)
    * def returnHeaders = generateHeaders(read('classpath:data/Input/Headers.json'))
    * print returnHeaders
    * def returnRequestBody = parseJson(read('classpath:data/Input/<requestBody>'))
    * print returnRequestBody
    Given url hostUrl
    And path returnPath
    And headers returnHeaders
    And request returnRequestBody
    When method post
    Then status <Expected_Response_Code>
    * print response
    * def idempotencyKey = returnHeaders['Idempotency-Key']
    * print idempotencyKey
    * def correlationId = returnHeaders['X-Correlation-Id']
    * print correlationId
    * mapExpectedValues(idempotencyKey,'Return',returnRequestBody)
    * def expectedResponse = parseJson(read('classpath:data/Output/<Expected_Response_Body>'))
    * print expectedResponse
    * match response == expectedResponse
    * def appNameUpper = ('<Kroger_Application_Name>').toUpperCase()
    * def cardLength = ('<cardNumber>').length()
    * def dbConfig = read('classpath:data/Input/DbConfig.json')
    * print dbConfig
    * def idempotencyRecords = karate.fromString(Java.type('com.kroger.payments.solutran.utils.GetDBRecords').retrieveCosmosDataEntry(dbConfig, idempotencyKey,'idempotency'))
    * print idempotencyRecords
    * def transactionId = idempotencyRecords.transactionId
    * print transactionId
    * def transactionRecords = karate.fromString(Java.type('com.kroger.payments.solutran.utils.GetDBRecords').retrieveCosmosDataEntry(dbConfig, transactionId,'transaction'))
    * print transactionRecords
    * def originalTransactionRecords = karate.fromString(Java.type('com.kroger.payments.solutran.utils.GetDBRecords').retrieveCosmosDataEntry(dbConfig, originalTransactionId,'transaction'))
    * print originalTransactionRecords
    * def originalResponseS3TranId =  originalTransactionRecords.processorResponse.solutranV1PurchaseResponse.TransInfo.S3TranID
    * def originalResponseS3PurAmt =  originalTransactionRecords.processorResponse.solutranV1PurchaseResponse.TransInfo.S3PurAmt
    * def originalRequestTotalTranAmt =  originalTransactionRecords.processorRequest.solutranV1PurchaseRequest.TransInfo.TotalTranAmt
    * def originalRequestTotalNetAmt =  originalTransactionRecords.processorRequest.solutranV1PurchaseRequest.TransInfo.TotalNetAmt
    * def originalRequestRetaiLoc =  originalTransactionRecords.processorRequest.solutranV1PurchaseRequest.TransInfo.RetaiLoc
    * def expectedLocality = purchaseRequestBody.order.customer.shippingLocation.address.locality
    * def dbStoreId = '<storeId>'
    * def expectedDBStoreId = (dbStoreId == '##REMOVE##') ? '##null' : (dbStoreId == '##NULL##' ? '' : dbStoreId)
    * def dbFacId = '<facilityId>'
    * def expectedDBFacId = (dbFacId == '##REMOVE##') ? null : (dbFacId == '##NULL##' ? '' : dbFacId)
    * def expectedDbResult = read('classpath:data/Output/<Expected_DB_Result>')
    * print expectedDbResult
    * match transactionRecords ==  expectedDbResult
    * def expectedProcessorRequest = parseJson(read('classpath:data/Output/<Expected_Processor_Request>'))
    * print expectedProcessorRequest
    * match transactionRecords.processorRequest ==  expectedProcessorRequest
    * def paddedRetaiLoc = '00' + originalRequestRetaiLoc
    * def expectedProcessorResponse = parseJson(read('classpath:data/Output/<Expected_Processor_Response>'))
    * print expectedProcessorResponse
    * match transactionRecords.processorResponse ==  expectedProcessorResponse
    Examples:
      | Java.type('com.krogerqa.karatecentral.utilities.Excel').getEnabledExcelTests('/src/test/resources/data/Excel/Returning.xlsx',  'Return') |

  @regression @testReturn
  Scenario Outline: Validate Solutran Return Validations - <Test Case>
    * def crossReferenceId = generateOrderId('<crossReferenceId>')
    * def returnHeaders = generateHeaders(read('classpath:data/Input/Headers.json'))
    * print returnHeaders
    * def returnRequestBody = parseJson(read('classpath:data/Input/<requestBody>'))
    * print returnRequestBody
    * def expectedResponse = parseJson(read('classpath:data/Output/<Expected_Response_Body>'))
    * print expectedResponse
    Given url hostUrl
    And path returnPath
    And headers returnHeaders
    And request returnRequestBody
    When method post
    Then status <Expected_Response_Code>
    * print response
    * match response contains only deep expectedResponse
    Examples:
      | Java.type('com.krogerqa.karatecentral.utilities.Excel').getEnabledExcelTests('/src/test/resources/data/Excel/Returning.xlsx',  'ReturnValidations') |