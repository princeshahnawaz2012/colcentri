@javascript
Feature: Reorder task within the task list view

  Background:
    Given @mislav exists and is logged in
    And I am in the project called "Colcentric"
    And the following task lists with associations exist:
      | name         | project |
      | Bugfixes     | Colcentric |
      | Next release | Colcentric |
    And I go to the "colcentric" tasks page

  Scenario: Reorder task list
    When I follow "Reorder Task Lists"
    And I drag the task list "Bugfixes" above "Next release"
    And I follow "Done reorder"
    And I wait for 1 second
    Then I should see the task list "Bugfixes" before "Next release"
