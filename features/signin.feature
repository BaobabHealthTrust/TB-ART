Feature: Signing in 
  In order to securely access the system's features
  Users should have to sign in with a user name and password

  @selenium
  Scenario: User who has not signed in cannot access secured pages
    Given I am not logged in
    When I go to the search page
    Then I should be on the login page
    And I should see the question "Enter user name"
