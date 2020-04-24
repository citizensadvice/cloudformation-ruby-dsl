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
      def getVersionScript = "rake prerelease_version[${env.BUILD_NUMBER}]"
      if (env.BRANCH_NAME == 'master') {
        getVersionScript = 'rake current_version'
      }
      else if (env.BRANCH_NAME == 'develop') {
        // Covered by default setting. Leaving the branch here as a reminder to figure out the whole flow.
      }
      else {
        // Do we need to build PRs as artifacts?
        // Should this return a different prerelease track? "alpha", or "pr_${pr_number}" maybe?        
      }
      def version = sh(script: getVersionScript, returnStdout: true).trim()
      def buildTime = now.format("yyyyddHHmmss", TimeZone.getTimeZone('UTC'))
      def packageFileName = "cloudformation-ruby-dsl-${version}+${buildTime}.gem"
      echo("echo gem build cloudformation-ruby-dsl --output=${packageFileName}")

      def secrets = [
          [$class: 'VaultSecret', path: 'secret/devops/sonatype_nexus', secretValues: [
              [$class: 'VaultSecretValue', envVar: 'NEXUS_USER', vaultKey: 'username'],
              [$class: 'VaultSecretValue', envVar: 'NEXUS_PASSWORD', vaultKey: 'password']]]
      ]

      wrap([$class: 'VaultBuildWrapper', vaultSecrets: secrets]) {
        sh("Using nexus user '$NEXUS_USER'")
        echo("gem nexus --credential \"\$NEXUS_USER:\$NEXUS_PASSWORD\" --nexus-config .nexus.config ${packageFileName}")
      }
  }
}
