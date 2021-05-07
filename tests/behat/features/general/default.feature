Feature: Validate that the site comes up without a 500 HTTP errors

  Scenario:  Check that the home page comes up without a 500
    When I visit "/"
    Then I should not get a "500" HTTP response
    And I should get a "200" HTTP response
