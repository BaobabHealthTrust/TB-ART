Feature: Clinician Visit
  As a clinician
  I want to be able to evaluate an ART patient using the system
  So that I can record their ART reason for eligibility and staging criteria

  @selenium
  Scenario: View the ART clinician encounter
    Given I am signed in at the clinician station
    And the patient is "Child"
    When I start the task "Art Clinician Visit"
    Then I should see "Stage 1 Conditions (adults and children)"                                    
    
  @selenium
  Scenario: Staging a child with a stage 1 condition
    Given I am signed in at the clinician station
    And the patient is "Child"
    When I start the task "Art Clinician Visit"
    Then I should see "Stage 1 Conditions (adults and children)"                                        
    When I press "Next"
    Then I should see "Stage 1 Conditions (children only)"
    When I select an option
    And I press "Next" until I see "New CD4 percent available?"
    And I select the option "No"
    And I press "Next"
    Then I should see "New Lymphocyte count available?"
    When I select the option "No"
    And I press "Next"
    Then I should see "Summary"
    And I should see "WHO STAGE I PEDS"
    And I should see "UNKNOWN"
