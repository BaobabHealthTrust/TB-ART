Feature: Signing in 
  In order to securely access the system's features
  Users should have to sign in with a user name and password

  Scenario: View login page
    Given I am on the login page
#    Then dump the page
#    Then lynxdump the page
    Then I should see "Enter user name"
