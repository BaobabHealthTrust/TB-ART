Feature: Clinician Visit
  As a clinician
  I want to be able to evaluate an ART patient using the system
  So that I can record their ART reason for eligibility and staging criteria

  @selenium
  Scenario: User who has not signed in cannot access secured pages
    Given I am logged in at the clinician station
    And the patient is "Child"
    When I start the task "Art Clinician Visit"
    Then I should see the question "Stage 1 Conditions (adults and children)"