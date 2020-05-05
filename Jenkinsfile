#!/usr/bin/env groovy

devImageTag = "cfrdsl:dev"

node('docker && awsaccess') {
  cleanWorkspace()
  
  stage('Checkout') {
    sh 'git config --global user.name jenkins && ' +
      'git config --global user.email cab-jenkins@citizensadvice.org.uk'
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
      withVaultSecrets([NEXUS_USER: 'secret/devops/sonatype_nexus, username', NEXUS_PASSWORD: 'secret/devops/sonatype_nexus, password']) {
        if (env.BRANCH_NAME == 'master') {
          sh("rake release")
        }
      }
    }
  }
}
