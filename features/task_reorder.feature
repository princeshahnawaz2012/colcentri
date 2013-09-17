@javascript
Feature: Reorder task within the task list view

  Background:
    Given @mislav exists and is logged in
    And I am in the project called "Colcentric"
    And the following task lists with associations exist:
      | name      | project |
      | This week | Colcentric |
      | Next week | Colcentric |
    And the following tasks with associations exist:
      | name                    | task_list | project |
      | Write more test         | This week | Colcentric |
      | Fix a drag and drop bug | This week | Colcentric |
      | Write a blog post       | Next week | Colcentric |
      | Publish a gem           | Next week | Colcentric |
    And I go to the "colcentric" tasks page

  Scenario: Reorder task within a task list
    When I follow "This week"
    And I drag the task "Fix a drag and drop bug" above "Write more test"
    And I wait for 1 second
    Then I should see the task "Fix a drag and drop bug" before "Write more test"

  Scenario: Reorder task to another task list
    When I drag the task "Write a blog post" above "Write more test"
    And I wait for 1 second
    Then I should see the task "Write a blog post" before "Write more test"
    And I should see the task called "Write a blog post" in the "This week" task list

  Scenario: I create and reorder a task
    When I follow "This week"
    And I follow "+ Add Task"
    And I fill in "Task title" with "Fix IE7"
    And I press "Add Task"
    And I wait for 1 second
    And I follow "This week"
    And I drag the task "Fix IE7" above "Write more test"
    And I wait for 1 second
    Then I should see the task "Fix IE7" before "Write more test"
