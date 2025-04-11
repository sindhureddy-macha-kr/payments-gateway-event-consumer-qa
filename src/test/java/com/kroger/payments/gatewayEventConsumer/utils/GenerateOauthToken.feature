Feature: Generate OAuth token
  Background:
  @oauth
  Scenario: Generate OAuth token
    * form field grant_type = 'client_credentials'
    * form field client_id = client_id
    * form field client_secret = client_secret
    * form field scope = scope
    Given url tokenUrl
    And header Content-Type = 'application/x-www-form-urlencoded'
    When method post
    Then status 200
    * def bearerToken = response.access_token