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
    stage('Install Requirements') {
      sh 'git config user.name jenkins && ' +
        'git config user.email cab-jenkins@citizensadvice.org.uk'
    }
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

    nexusGemRelease()

  }
}
