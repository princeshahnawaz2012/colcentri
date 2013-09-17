@tasks @javascript
Feature: When I view the time tracking reports globally

  Background:
    Given @mislav exists and is logged in
    And I am a participant in the organization called "ACME"
    And I am a participant in the organization called "Colcentric"
    And there is a project called "Colcentric Accounting"
    And there is a project called "ACME Marketing"
    And "mislav" is the owner of the project "Colcentric Accounting"
    And "mislav" is the owner of the project "ACME Marketing"
    And the project "Colcentric Accounting" belongs to "Colcentric" organization
    And the project "ACME Marketing" belongs to "ACME" organization
    And the following task lists with associations exist:
      | name          | project            |
      | Fake results  | Colcentric Accounting |
      | Send spam     | ACME Marketing     |
    And the following tasks with hours exists:
      | name                                   | task_list    | project            | comment             | hours  |
      | Calculate possible fake results        | Fake results | Colcentric Accounting | Working on it...    | 1h 30m |
      | Change numbers from last year books    | Fake results | Colcentric Accounting | I got this          | 2h     |
      | Post on Digg and Hacker News           | Send spam    | ACME Marketing     | So easy             | 30m    |
      | Send a weekly newsletter               | Send spam    | ACME Marketing     | K is helping me     | 5h     |

  Scenario: I can see the hours in time tracking
    When I go to time tracking
    Then I should see "1h 30m"
    And I should see "5h"
    And I should see "9h"

  Scenario: I can filter by organization
    When I go to time tracking
    And I select "Colcentric" from "hours_organization_filter_assigned"
    Then I should see "1h 30m"
    And I should not see "5h"
    And I should see "3h 30m"
    And I select "ACME" from "hours_organization_filter_assigned"
    Then I should not see "1h 30m"
    And I should see "5h"
    And I should see "5h 30m"

  Scenario: I can filter by project
    When I go to time tracking
    And I select "Colcentric Accounting" from "hours_project_filter_assigned"
    Then I should see "1h 30m"
    And I should not see "5h"
    And I should see "3h 30m"
    And I select "ACME Marketing" from "hours_project_filter_assigned"
    Then I should not see "1h 30m"
    And I should see "5h"
    And I should see "5h 30m"
