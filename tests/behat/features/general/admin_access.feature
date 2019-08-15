Feature: Validate that admin functionality is working

  @api
  Scenario:  Check that /admin/config can be accessed without 500 HTTP error
    Given I am logged in as a user with the "administrator" role
    When I visit "/admin/config"
    Then I should not get a "500" HTTP response
    And I should get a "200" HTTP response
    And I should see the heading "Configuration"
