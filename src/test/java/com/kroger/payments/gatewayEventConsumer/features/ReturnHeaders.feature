Feature: Validate Solutran Return Headers

  Background:
    * configure ssl = true
    * def getToken = callonce read('classpath:com/kroger/payments/solutran/utils/GenerateOauthToken.feature')
    * def bearerToken = 'Bearer ' + getToken.bearerToken
    * call read('classpath:com/kroger/payments/solutran/utils/TestUtils.feature')

  @regression @testReturn @smoke
  Scenario Outline: Validate Solutran Return Headers - <Test Case>
    * def headers = read('classpath:data/Input/Headers.json')
    * def returnHeaders = generateHeaders(headers)
    * print returnHeaders
    * def crossReferenceId = generateOrderId('<crossReferenceId>')
    * def requestBody = read('classpath:data/Input/<requestBody>')
    * print requestBody
    * def expectedResponse = read('classpath:data/Output/<Expected_Response_Body>')
    * print expectedResponse
    Given url hostUrl
    And path returnPath
    And headers returnHeaders
    And request requestBody
    When method post
    Then status <Expected_Response_Code>
    * print response
    * match response == expectedResponse

    Examples:
      | Java.type('com.krogerqa.karatecentral.utilities.Excel').getEnabledExcelTests('/src/test/resources/data/Excel/Returning.xlsx',  'ReturnHeaders') |