workflow "Build & Release" {
  on = "push"
  resolves = ["Post Success Message"]
}

action "Filter Master" {
  uses = "actions/bin/filter@master"
  args = "branch master"
}

action "Get Dependencies" {
  uses = "./.github/mix"
  needs = "Filter Master"
  args = "deps.get"
  env = {
    MIX_ENV = "dev"
  }
}

action "Run Tests" {
  uses = "./.github/mix"
  needs = "Get Dependencies"
  args = "test"
  env = {
    MIX_ENV = "test"
  }
}

action "Check Formatting" {
  uses = "./.github/mix"
  needs = "Get Dependencies"
  args = "format --check-formatted"
  env = {
    MIX_ENV = "dev"
  }
}

action "Create Release" {
  uses = "./.github/mix"
  needs = ["Run Tests", "Check Formatting"]
  args = "do deps.get, compile, release"
  secrets = ["COOKIE"]
}

action "Registry Login" {
  uses = "./.github/heroku"
  needs = "Filter Master"
  args = "container:login"
  secrets = ["HEROKU_API_KEY"]
}

action "Container Push" {
  uses = "./.github/heroku"
  needs = ["Create Release", "Registry Login"]
  args = "container:push web --app $HEROKU_APP_NAME"
  secrets = ["HEROKU_API_KEY", "HEROKU_APP_NAME"]
}

action "Container Release" {
  uses = "./.github/heroku"
  needs = "Container Push"
  args = "container:release web --app $HEROKU_APP_NAME"
  secrets = ["HEROKU_API_KEY", "HEROKU_APP_NAME"]
}

action "Post Success Message" {
  uses = "./actions/post-message"
  needs = ["Container Release"]
  secrets = ["WEBHOOK_URL"]
  args = "\"slack_actions\" has been deployed by $GITHUB_ACTOR"
}
