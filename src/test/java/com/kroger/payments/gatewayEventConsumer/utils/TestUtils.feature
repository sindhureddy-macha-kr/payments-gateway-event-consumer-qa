Feature: Test Utilities

  Background:
    * def uuid = function(){ return java.util.UUID.randomUUID() + '' }

  Scenario: Test Utilities
    * def generateHeaders =
    """
    function(headers) {
      for (const key in headers) {
        if (headers[key] == '##REMOVE##') {
          karate.remove('headers', '$.' + key)
        }
        if (headers[key] == '##NULL##') {
          headers[key] = ''
        }
        if ((key == 'X-Correlation-Id') && (headers[key] == '##GENERATE##')) {
          headers[key] = uuid()
        }
        if ((key == 'Idempotency-Key') && (headers[key] == '##GENERATE##')) {
          headers[key] = uuid()
        }
      }
      return headers
    }
    """
    * def parseJson =
      """
      function(jsonBody) {
        updateValues(jsonBody)
        return jsonBody
      }
      """
    * def generateOrderId =
      """
      function(crossRefId) {
        if (crossRefId == "##GENERATE##") {
          crossRefId = org.apache.commons.lang3.RandomStringUtils.random(19,false,true)
        }
        return crossRefId
      }
      """