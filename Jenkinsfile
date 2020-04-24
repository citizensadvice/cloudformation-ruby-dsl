#!/usr/bin/env groovy

devImageTag = "cfrdsl:dev"

node('docker && awsaccess') {
  cleanWorkspace()

  stage('Checkout') {
    checkout scm
  }

  stage("Build") {
    image = docker.build(devImageTag, "-f Dockerfile.dev .")
  }

  image.inside {
    stage('Run linter') {
      // TODO: [DP-108] fix rubocop violations
      sh 'bundle exec rubocop --fail-level F'
    }

    stage('Run unit tests') {
      sh 'AWS_REGION=eu-west-1 bundle exec rake spec'
    }

    stage('Publish coverage report') {
      publishHTML([
        allowMissing: false,
        alwaysLinkToLastBuild: true,
        keepAll: false,
        reportDir: 'coverage',
        reportFiles: 'index.html',
        reportName: 'Coverage report'
      ])
    }

    stage('Generate documentation') {
      sh 'bundle exec yardoc .'
      publishHTML([
        allowMissing: false,
        alwaysLinkToLastBuild: true,
        keepAll: false,
        reportDir: 'doc',
        reportFiles: 'index.html',
        reportName: 'cloudformation-ruby-dsl documentation'
      ])
    }

    stage('Push to repository') {
      def now = new Date()
      if (env.BRANCH_NAME == 'master') {
        def version = sh(script: 'rake current_version', returnStdOut: true)
      }
      else if (env.BRANCH_NAME == 'develop') {
        def version = sh(script: "rake prerelease_version[${env.BUILD_NUMBER}]", returnStdOut: true)
      }
      else {
        // Do we need to build PRs as artifacts?
        // Should this return a different prerelease track? "alpha", or "pr_${pr_number}" maybe?
        def version = sh(script: "rake prerelease_version[${env.BUILD_NUMBER}]", returnStdOut: true)
      }
      def buildTime = now.format("yyyyddHHmmss", TimeZone.getTimeZone('UTC'))
      def packageFileName = "cloudformation-ruby-dsl-${version}+${buildTime}.gem"
      echo("echo gem build cloudformation-ruby-dsl --output=${packageFileName}")
      echo("gem nexus --credential \"$NEXUS_USER:$NEXUS_PASSWORD\" --nexus-config nexus.config ${packageFileName}")
    }
  }
}
