#!/usr/bin/env groovy

/*
 * Copyright (C) 2019 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import org.jenkinsci.plugins.workflow.support.steps.build.DownstreamFailureCause
import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

def buildParameters = [
  string(name: 'GERRIT_REFSPEC', value: "${env.GERRIT_REFSPEC}"),
  string(name: 'GERRIT_EVENT_TYPE', value: "${env.GERRIT_EVENT_TYPE}"),
  string(name: 'GERRIT_PROJECT', value: "${env.GERRIT_PROJECT}"),
  string(name: 'GERRIT_BRANCH', value: "${env.GERRIT_BRANCH}"),
  string(name: 'GERRIT_CHANGE_NUMBER', value: "${env.GERRIT_CHANGE_NUMBER}"),
  string(name: 'GERRIT_PATCHSET_NUMBER', value: "${env.GERRIT_PATCHSET_NUMBER}"),
  string(name: 'GERRIT_EVENT_ACCOUNT_NAME', value: "${env.GERRIT_EVENT_ACCOUNT_NAME}"),
  string(name: 'GERRIT_EVENT_ACCOUNT_EMAIL', value: "${env.GERRIT_EVENT_ACCOUNT_EMAIL}"),
  string(name: 'GERRIT_CHANGE_COMMIT_MESSAGE', value: "${env.GERRIT_CHANGE_COMMIT_MESSAGE}"),
  string(name: 'GERRIT_HOST', value: "${env.GERRIT_HOST}"),
  string(name: 'GERGICH_PUBLISH', value: "${env.GERGICH_PUBLISH}"),
  string(name: 'MASTER_BOUNCER_RUN', value: "${env.MASTER_BOUNCER_RUN}")
]

def dockerDevFiles = [
  '^docker-compose/',
  '^build/common_docker_build_steps.sh',
  '^script/canvas_update',
  '^docker-compose.yml',
  '^Dockerfile$',
  '^lib/tasks/',
  'Jenkinsfile.docker-smoke'
]

def jenkinsFiles = [
  'Jenkinsfile*',
  '^docker-compose.new-jenkins*.yml',
  'build/new-jenkins/*'
]

def getDockerWorkDir() {
  return env.GERRIT_PROJECT == "canvas-lms" ? "/usr/src/app" : "/usr/src/app/gems/plugins/${env.GERRIT_PROJECT}"
}

def getLocalWorkDir() {
  return env.GERRIT_PROJECT == "canvas-lms" ? "." : "gems/plugins/${env.GERRIT_PROJECT}"
}

// if the build never starts or gets into a node block, then we
// can never load a file. and a very noisy/confusing error is thrown.
def ignoreBuildNeverStartedError(block) {
  try {
    block()
  }
  catch (org.jenkinsci.plugins.workflow.steps.MissingContextVariableException ex) {
    if (!ex.message.startsWith('Required context class hudson.FilePath is missing')) {
      throw ex
    }
    else {
      echo "ignored MissingContextVariableException: \n${ex.message}"
    }
    // we can ignore this very noisy error
  }
}

// return false if the current patchset tag doesn't match the
// mainline publishable tag. i.e. ignore pg-9.5 builds
def isPatchsetPublishable() {
  env.PATCHSET_TAG == env.PUBLISHABLE_TAG
}

def isPatchsetRetriggered() {
  if(env.IS_AUTOMATIC_RETRIGGER == '1') {
    return true
  }

  def userCause = currentBuild.getBuildCauses('com.sonyericsson.hudson.plugins.gerrit.trigger.hudsontrigger.GerritUserCause')

  return userCause && userCause[0].shortDescription.contains('Retriggered')
}

def cleanupFn(status) {
  ignoreBuildNeverStartedError {
    execute 'bash/docker-cleanup.sh --allow-failure'
  }
}

def postFn(status) {
  try {
    def requestStartTime = System.currentTimeMillis()
    node('master') {
      def requestEndTime = System.currentTimeMillis()

      reportToSplunk('node_request_time', [
        'nodeName': 'master',
        'nodeLabel': 'master',
        'requestTime': requestEndTime - requestStartTime,
      ])

      failureReport.publishReportFromArtifacts('Rspec Test Failures', 'rspec')
      failureReport.publishReportFromArtifacts('Selenium Test Failures', 'selenium')
      failureReport.submit()

      if(status == 'SUCCESS' && configuration.isChangeMerged() && isPatchsetPublishable()) {
        dockerUtils.tagRemote(env.PATCHSET_TAG, env.MERGE_TAG)
      }
    }
  } finally {
    if(status == 'FAILURE') {
      maybeSlackSendFailure()
      maybeRetrigger()
    } else if(status == 'SUCCESS') {
      maybeSlackSendSuccess()
    }
  }
}

def shouldPatchsetRetrigger() {
  // NOTE: The IS_AUTOMATIC_RETRIGGER check is here to ensure that the parameter is properly defined for the triggering job.
  // If it isn't, we have the risk of triggering this job over and over in an infinite loop.
  return env.IS_AUTOMATIC_RETRIGGER == '0' && (
    env.GERRIT_EVENT_TYPE == 'change-merged' ||
    configuration.getBoolean('change-merged') && configuration.getBoolean('enable-automatic-retrigger', '0')
  )
}

def maybeRetrigger() {
  if(shouldPatchsetRetrigger() && !isPatchsetRetriggered()) {
    def retriggerParams = currentBuild.rawBuild.getAction(ParametersAction).getParameters()

    retriggerParams = retriggerParams.findAll { record ->
      record.name != 'IS_AUTOMATIC_RETRIGGER'
    }

    retriggerParams << new StringParameterValue('IS_AUTOMATIC_RETRIGGER', "1")

    build(job: env.JOB_NAME, parameters: retriggerParams, propagate: false, wait: false)
  }
}

def maybeSlackSendFailure() {
  if(configuration.isChangeMerged()) {
    def branchSegment = env.GERRIT_BRANCH ? "[$env.GERRIT_BRANCH]" : ''
    def authorSlackId = env.GERRIT_EVENT_ACCOUNT_EMAIL ? slackUserIdFromEmail(email: env.GERRIT_EVENT_ACCOUNT_EMAIL, botUser: true, tokenCredentialId: 'slack-user-id-lookup') : ''
    def authorSlackMsg = authorSlackId ? "<@$authorSlackId>" : env.GERRIT_EVENT_ACCOUNT_NAME
    def authorSegment = "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> by ${authorSlackMsg} failed against ${branchSegment}"
    def extra = "Please investigate the cause of the failure, and respond to this message with your diagnosis. If you need help, don't hesitate to tag @ oncall and our on call will assist in looking at the build. Further details of our post-merge failure process can be found at this <${configuration.getFailureWiki()}|link>. Thanks!"

    slackSend(
      channel: getSlackChannel(),
      color: 'danger',
      message: "${authorSegment}. Build <${env.BUILD_URL}|#${env.BUILD_NUMBER}>\n\n$extra"
    )
  }
}

def maybeSlackSendSuccess() {
  if(configuration.isChangeMerged() && isPatchsetRetriggered()) {
    slackSend(
      channel: getSlackChannel(),
      color: 'good',
      message: "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> succeeded on re-trigger. Build <${env.BUILD_URL}|#${env.BUILD_NUMBER}>"
    )
  }
}

def maybeSlackSendRetrigger() {
  if(configuration.isChangeMerged() && isPatchsetRetriggered()) {
    slackSend(
      channel: getSlackChannel(),
      color: 'warning',
      message: "Patchset <${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> by ${env.GERRIT_EVENT_ACCOUNT_EMAIL} has been re-triggered. Build <${env.BUILD_URL}|#${env.BUILD_NUMBER}>"
    )
  }
}

def slackSendCacheBuild(block) {
  def buildStartTime = System.currentTimeMillis()

  block()

  def buildEndTime = System.currentTimeMillis()

  def buildLog = sh(script: 'cat tmp/docker-build-short.log', returnStdout: true).trim()

  slackSend(
    channel: '#jenkins_cache_noisy',
    message: """<${env.GERRIT_CHANGE_URL}|#${env.GERRIT_CHANGE_NUMBER}> on ${env.GERRIT_PROJECT}. Build <${env.BUILD_URL}|#${env.BUILD_NUMBER}>
      Duration: ${buildEndTime - buildStartTime}ms
      Instance: ${env.NODE_NAME}

      ```${buildLog}```
    """
  )
}

// These functions are intentionally pinned to GERRIT_EVENT_TYPE == 'change-merged' to ensure that real post-merge
// builds always run correctly. We intentionally ignore overrides for version pins, docker image paths, etc when
// running real post-merge builds.
// =========
def getPluginVersion(plugin) {
  if(env.GERRIT_BRANCH.contains('stable/')) {
    return configuration.getString("pin-commit-$plugin", env.GERRIT_BRANCH)
  }
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? 'master' : configuration.getString("pin-commit-$plugin", "master")
}

def getSlackChannel() {
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? '#canvas_builds' : '#devx-bots'
}

@groovy.transform.Field def CANVAS_BUILDS_REFSPEC_REGEX = /\[canvas\-builds\-refspec=(.+?)\]/

def getCanvasBuildsRefspec() {
  def commitMessage = env.GERRIT_CHANGE_COMMIT_MESSAGE ? new String(env.GERRIT_CHANGE_COMMIT_MESSAGE.decodeBase64()) : null

  if(env.GERRIT_EVENT_TYPE == 'change-merged' || !commitMessage || !(commitMessage =~ CANVAS_BUILDS_REFSPEC_REGEX).find()) {
    return 'master'
  }

  return (commitMessage =~ CANVAS_BUILDS_REFSPEC_REGEX).findAll()[0][1]
}

@groovy.transform.Field def CANVAS_LMS_REFSPEC_REGEX = /\[canvas\-lms\-refspec=(.+?)\]/
def getCanvasLmsRefspec() {
  // If stable branch, first search commit message for canvas-lms-refspec. If not present use stable branch head on origin.
  if(env.GERRIT_BRANCH.contains('stable/')) {
    def commitMessage = env.GERRIT_CHANGE_COMMIT_MESSAGE ? new String(env.GERRIT_CHANGE_COMMIT_MESSAGE.decodeBase64()) : null
    if((commitMessage =~ CANVAS_LMS_REFSPEC_REGEX).find()) {
      return configuration.canvasLmsRefspec()
    }
    return "+refs/heads/$GERRIT_BRANCH:refs/remotes/origin/$GERRIT_BRANCH"
  }
  return env.GERRIT_EVENT_TYPE == 'change-merged' ? configuration.canvasLmsRefspecDefault() : configuration.canvasLmsRefspec()
}
// =========

def rebaseHelper(branch, commitHistory = 100) {
  git.fetch(branch, commitHistory)
  if (!git.hasCommonAncestor(branch)) {
    error "Error: your branch is over ${commitHistory} commits behind $GERRIT_BRANCH, please rebase your branch manually."
  }
  if (!git.rebase(branch)) {
    error "Error: Rebase couldn't resolve changes automatically, please resolve these conflicts locally."
  }
}

library "canvas-builds-library@${getCanvasBuildsRefspec()}"

configuration.setUseCommitMessageFlags(env.GERRIT_EVENT_TYPE != 'change-merged')

pipeline {
  agent none
  options {
    ansiColor('xterm')
    timestamps()
  }

  environment {
    GERRIT_PORT = '29418'
    GERRIT_URL = "$GERRIT_HOST:$GERRIT_PORT"
    BUILD_REGISTRY_FQDN = configuration.buildRegistryFQDN()
    BUILD_IMAGE = configuration.buildRegistryPath()
    POSTGRES = configuration.postgres()
    POSTGRES_CLIENT = configuration.postgresClient()
    SKIP_CACHE = configuration.skipCache()

    // e.g. postgres-12-ruby-2.6
    TAG_SUFFIX = imageTag.suffix()


    // e.g. canvas-lms:01.123456.78-postgres-12-ruby-2.6
    PATCHSET_TAG = imageTag.patchset()

    // e.g. canvas-lms:01.123456.78-postgres-12-ruby-2.6
    PUBLISHABLE_TAG = imageTag.publishableTag()

    // e.g. canvas-lms:master when not on another branch
    MERGE_TAG = imageTag.mergeTag()

    // e.g. canvas-lms:01.123456.78; this is for consumers like Portal 2 who want to build a patchset
    EXTERNAL_TAG = imageTag.externalTag()

    ALPINE_MIRROR = configuration.alpineMirror()
    NODE = configuration.node()
    RUBY = configuration.ruby() // RUBY_VERSION is a reserved keyword for ruby installs

    JS_DEBUG_IMAGE = "$BUILD_IMAGE-js-debug:${imageTagVersion()}-$TAG_SUFFIX"

    RUBY_RUNNER_PREFIX = "$BUILD_IMAGE-ruby-runner"
    YARN_RUNNER_PREFIX = "$BUILD_IMAGE-yarn-runner"
    WEBPACK_BUILDER_PREFIX = "$BUILD_IMAGE-webpack-builder"
    WEBPACK_CACHE_PREFIX = "$BUILD_IMAGE-webpack-cache"

    WEBPACK_BUILDER_IMAGE = "$WEBPACK_BUILDER_PREFIX:${imageTagVersion()}-$TAG_SUFFIX"

    IMAGE_CACHE_BUILD_SCOPE = configuration.gerritChangeNumber()
    IMAGE_CACHE_MERGE_SCOPE = configuration.gerritBranchSanitized()

    CASSANDRA_IMAGE_TAG=imageTag.cassandra()
    DYNAMODB_IMAGE_TAG=imageTag.dynamodb()
    POSTGRES_IMAGE_TAG=imageTag.postgres()
    // This is primarily for the plugin build
    // for testing canvas-lms changes against plugin repo changes
    CANVAS_BUILDS_REFSPEC = getCanvasBuildsRefspec()
    CANVAS_LMS_REFSPEC = getCanvasLmsRefspec()
    DOCKER_WORKDIR = getDockerWorkDir()
    LOCAL_WORKDIR = getLocalWorkDir()
  }

  stages {
    stage('Environment') {
      steps {
        script {
          // Ensure that all build flags are compatible.
          if(configuration.getBoolean('change-merged') && configuration.isValueDefault('build-registry-path')) {
            error "Manually triggering the change-merged build path must be combined with a custom build-registry-path"
            return
          }

          maybeSlackSendRetrigger()

          // Use a nospot instance for now to avoid really bad UX. Jenkins currently will
          // wait for the current steps to complete (even wait to spin up a node), causing
          // extremely long wait times for a restart. Investigation in DE-166 / DE-158.
          protectedNode('canvas-docker-nospot', { status -> cleanupFn(status) }, { status -> postFn(status) }) {
            timedStage('Setup') {
              timeout(time: 5) {
                echo "Cleaning Workspace From Previous Runs"
                sh 'ls -A1 | xargs rm -rf'
                sh 'find .'
                cleanAndSetup()
                def refspecToCheckout = env.GERRIT_PROJECT == "canvas-lms" ? env.GERRIT_REFSPEC : env.CANVAS_LMS_REFSPEC
                checkoutRepo("canvas-lms", refspecToCheckout, 100)

                if(env.GERRIT_PROJECT != "canvas-lms") {
                  dir(env.LOCAL_WORKDIR) {
                    checkoutRepo(GERRIT_PROJECT, env.GERRIT_REFSPEC, 2)
                  }

                  // Plugin builds using the checkout above will create this @tmp file, we need to remove it
                  sh 'rm -vr gems/plugins/*@tmp'
                }

                buildParameters += string(name: 'CANVAS_BUILDS_REFSPEC', value: "${env.CANVAS_BUILDS_REFSPEC}")
                buildParameters += string(name: 'PATCHSET_TAG', value: "${env.PATCHSET_TAG}")
                buildParameters += string(name: 'POSTGRES', value: "${env.POSTGRES}")
                buildParameters += string(name: 'RUBY', value: "${env.RUBY}")

                if (currentBuild.projectName.contains("rails-6")) {
                  buildParameters += string(name: 'CANVAS_RAILS6_0', value: "${env.CANVAS_RAILS6_0}")
                }

                // If modifying any of our Jenkinsfiles set JENKINSFILE_REFSPEC for sub-builds to use Jenkinsfiles in
                // the gerrit rather than master.
                if(env.GERRIT_PROJECT == 'canvas-lms' && git.changedFiles(jenkinsFiles, 'HEAD^') ) {
                    buildParameters += string(name: 'JENKINSFILE_REFSPEC', value: "${env.GERRIT_REFSPEC}")
                }

                if (env.GERRIT_PROJECT != "canvas-lms") {
                  // the plugin builds require the canvas lms refspec to be different. so only
                  // set this refspec if the main build is requesting it to be set.
                  // NOTE: this is only being set in main-from-plugin build. so main-canvas wont run this.
                  buildParameters += string(name: 'CANVAS_LMS_REFSPEC', value: env.CANVAS_LMS_REFSPEC)
                }

                gems = configuration.plugins()
                echo "Plugin list: ${gems}"
                def pluginsToPull = []
                gems.each {
                  if (env.GERRIT_PROJECT != it) {
                    pluginsToPull.add([name: it, version: getPluginVersion(it), target: "gems/plugins/$it"])
                  }
                }

                pluginsToPull.add([name: 'qti_migration_tool', version: getPluginVersion('qti_migration_tool'), target: "vendor/qti_migration_tool"])

                pullRepos(pluginsToPull)
              }
            }

            if(!configuration.isChangeMerged() && env.GERRIT_PROJECT == 'canvas-lms' && !configuration.skipRebase()) {
              timedStage('Rebase') {
                timeout(time: 2) {
                  rebaseHelper(GERRIT_BRANCH)
                  if ( GERRIT_BRANCH ==~ /dev\/.*/ ) {
                    rebaseHelper("master")
                  }

                  if(!env.JOB_NAME.endsWith('Jenkinsfile') && git.changedFiles(jenkinsFiles, 'origin/master')) {
                      error "Jenkinsfile has been updated. Please retrigger your patchset for the latest updates."
                  }
                }
              }
            }

            timedStage('Build Docker Image') {
              timeout(time: 30) {
                if (!configuration.isChangeMerged() && configuration.skipDockerBuild()) {
                  sh './build/new-jenkins/docker-with-flakey-network-protection.sh pull $MERGE_TAG'
                  sh 'docker tag $MERGE_TAG $PATCHSET_TAG'
                } else {
                  def cacheScope = configuration.isChangeMerged() ? env.IMAGE_CACHE_MERGE_SCOPE : env.IMAGE_CACHE_BUILD_SCOPE

                  slackSendCacheBuild {
                    withEnv([
                      "CACHE_LOAD_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
                      "CACHE_LOAD_FALLBACK_SCOPE=${env.IMAGE_CACHE_BUILD_SCOPE}",
                      "CACHE_SAVE_SCOPE=${cacheScope}",
                      "COMPILE_ADDITIONAL_ASSETS=${configuration.isChangeMerged() ? 1 : 0}",
                      "JS_BUILD_NO_UGLIFY=${configuration.isChangeMerged() ? 0 : 1}",
                      "RUBY_RUNNER_PREFIX=${env.RUBY_RUNNER_PREFIX}",
                      "WEBPACK_BUILDER_PREFIX=${env.WEBPACK_BUILDER_PREFIX}",
                      "WEBPACK_BUILDER_TAG=${env.WEBPACK_BUILDER_IMAGE}",
                      "WEBPACK_CACHE_PREFIX=${env.WEBPACK_CACHE_PREFIX}",
                      "YARN_RUNNER_PREFIX=${env.YARN_RUNNER_PREFIX}",
                    ]) {
                      sh "build/new-jenkins/docker-build.sh $PATCHSET_TAG"
                    }
                  }
                }

                sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push $PATCHSET_TAG"

                if(configuration.isChangeMerged()) {
                  def GIT_REV = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                  sh "docker tag \$PATCHSET_TAG \$BUILD_IMAGE:${GIT_REV}"

                  sh "./build/new-jenkins/docker-with-flakey-network-protection.sh push \$BUILD_IMAGE:${GIT_REV}"
                }

                sh(script: """
                  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_BUILDER_PREFIX || true
                  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $YARN_RUNNER_PREFIX || true
                  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $RUBY_RUNNER_PREFIX || true
                  ./build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_CACHE_PREFIX
                """, label: 'upload cache images')

                def hasWebpackBuilderImage = sh(script: "./build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_BUILDER_IMAGE", returnStatus: true)

                // If we are unable to push up the webpack builder image, then this
                // build should use the currently cached image.
                if (hasWebpackBuilderImage != 0) {
                  def webpackBuilderLabel = sh(script: "docker inspect $PATCHSET_TAG --format '{{ .Config.Labels.WEBPACK_BUILDER_SELECTED_TAG }}'", returnStdout: true)

                  dockerUtils.tagRemote(webpackBuilderLabel, env.WEBPACK_BUILDER_IMAGE)
                }

                if (isPatchsetPublishable()) {
                  sh 'docker tag $PATCHSET_TAG $EXTERNAL_TAG'
                  sh './build/new-jenkins/docker-with-flakey-network-protection.sh push $EXTERNAL_TAG'
                }
              }
            }


            timedStage('Run Migrations') {
              timeout(time: 10) {
                withEnv([
                  "COMPOSE_FILE=docker-compose.new-jenkins.yml",
                  "POSTGRES_PASSWORD=sekret"
                ]) {
                  migrations.runMigrations()
                  sh 'docker-compose down --remove-orphans'
                }
              }
            }

            stage('Parallel Run Tests') {
              withEnv([
                "CASSANDRA_IMAGE_TAG=${migrations.cassandraTag()}",
                "DYNAMODB_IMAGE_TAG=${migrations.dynamodbTag()}",
                "POSTGRES_IMAGE_TAG=${migrations.postgresTag()}"
              ]) {
                def stages = [:]

                if (configuration.isChangeMerged()) {
                  echo 'adding Build Docker Image Cache'
                  stages['Build Docker Image Cache'] = {
                    withEnv([
                      "CACHE_LOAD_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
                      "CACHE_LOAD_FALLBACK_SCOPE=${env.IMAGE_CACHE_BUILD_SCOPE}",
                      "CACHE_SAVE_SCOPE=${env.IMAGE_CACHE_MERGE_SCOPE}",
                      "COMPILE_ADDITIONAL_ASSETS=0",
                      "JS_BUILD_NO_UGLIFY=1",
                      "RUBY_RUNNER_PREFIX=${env.RUBY_RUNNER_PREFIX}",
                      "WEBPACK_BUILDER_PREFIX=${env.WEBPACK_BUILDER_PREFIX}",
                      "WEBPACK_CACHE_PREFIX=${env.WEBPACK_CACHE_PREFIX}",
                      "YARN_RUNNER_PREFIX=${env.YARN_RUNNER_PREFIX}",
                    ]) {
                      slackSendCacheBuild {
                        sh "build/new-jenkins/docker-build.sh"
                      }

                      sh "build/new-jenkins/docker-with-flakey-network-protection.sh push $WEBPACK_CACHE_PREFIX"
                    }
                  }
                }

                if (!configuration.isChangeMerged() && env.GERRIT_PROJECT == 'canvas-lms') {
                  echo 'adding Linters'
                  timedStage('Linters', stages, {
                    credentials.withGerritCredentials {
                      withEnv([
                        "PLUGINS_LIST=${configuration.plugins().join(' ')}"
                      ]) {
                        sh 'build/new-jenkins/linters/run-gergich.sh'
                      }
                    }
                    if (env.MASTER_BOUNCER_RUN == '1' && !configuration.isChangeMerged()) {
                      credentials.withMasterBouncerCredentials {
                        sh 'build/new-jenkins/linters/run-master-bouncer.sh'
                      }
                    }
                  })
                }

                echo 'adding Consumer Smoke Test'
                timedStage('Consumer Smoke Test', stages, {
                  sh 'build/new-jenkins/consumer-smoke-test.sh'
                })

                echo 'adding Vendored Gems'
                buildStage.makeFromJob('Vendored Gems', '/Canvas/test-suites/vendored-gems', stages, buildParameters + [
                    string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                    string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                    string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}")
                  ]
                )

                if(configuration.getBoolean('upload-js-debug-image', 'false')) {
                  echo 'adding Javascript (Debug Image Upload)'
                  buildStage.makeFromJob('Javascript (Debug Image Upload)', '/Canvas/test-suites/JS', stages, buildParameters + [
                      string(name: 'JS_DEBUG_IMAGE_TAG', value: env.JS_DEBUG_IMAGE),
                      string(name: 'WEBPACK_BUILDER_TAG', value: env.WEBPACK_BUILDER_IMAGE),
                      string(name: 'TEST_SUITE', value: "upload"),
                      string(name: 'WEBPACK_BUILDER_TAG', value: env.WEBPACK_BUILDER_IMAGE),
                    ], true, "testReport"
                  )
                }

                echo 'adding Javascript (Jest)'
                buildStage.makeFromJob('Javascript (Jest)', '/Canvas/test-suites/JS', stages, buildParameters + [
                    string(name: 'WEBPACK_BUILDER_TAG', value: env.WEBPACK_BUILDER_IMAGE),
                    string(name: 'TEST_SUITE', value: "jest"),
                    string(name: 'WEBPACK_BUILDER_TAG', value: env.WEBPACK_BUILDER_IMAGE),
                  ], true, "testReport"
                )

                echo 'adding Javascript (Coffeescript)'
                buildStage.makeFromJob('Javascript (Coffeescript)', '/Canvas/test-suites/JS', stages, buildParameters + [
                    string(name: 'WEBPACK_BUILDER_TAG', value: env.WEBPACK_BUILDER_IMAGE),
                    string(name: 'TEST_SUITE', value: "coffee"),
                  ], true, "testReport"
                )

                echo 'adding Javascript (Karma)'
                buildStage.makeFromJob('Javascript (Karma)', '/Canvas/test-suites/JS', stages, buildParameters + [
                    string(name: 'WEBPACK_BUILDER_TAG', value: env.WEBPACK_BUILDER_IMAGE),
                    string(name: 'TEST_SUITE', value: "karma"),
                    string(name: 'WEBPACK_BUILDER_TAG', value: env.WEBPACK_BUILDER_IMAGE),
                  ], true, "testReport"
                )

                echo 'adding Contract Tests'
                buildStage.makeFromJob('Contract Tests', '/Canvas/test-suites/contract-tests', stages, buildParameters + [
                    string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                    string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                    string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}")
                  ]
                )

                if (sh(script: 'build/new-jenkins/check-for-migrations.sh', returnStatus: true) == 0) {
                  echo 'adding CDC Schema check'
                  buildStage.makeFromJob('CDC Schema Check', '../Canvas/cdc-event-transformer-master', stages, buildParameters + [
                      string(name: 'CANVAS_LMS_IMAGE_PATH', value: "${env.PATCHSET_TAG}")
                    ]
                  )
                }
                else {
                  echo 'no migrations added, skipping CDC Schema check'
                }

                if (
                  !configuration.isChangeMerged() &&
                  (
                    dir(env.LOCAL_WORKDIR){ (sh(script: '${WORKSPACE}/build/new-jenkins/spec-changes.sh', returnStatus: true) == 0) } ||
                    configuration.forceFailureFSC() == '1'
                  )
                ) {
                  echo 'adding Flakey Spec Catcher'
                  buildStage.makeFromJob('Flakey Spec Catcher', '/Canvas/test-suites/flakey-spec-catcher', stages, buildParameters + [
                      string(name: 'CASSANDRA_IMAGE_TAG', value: "${env.CASSANDRA_IMAGE_TAG}"),
                      string(name: 'DYNAMODB_IMAGE_TAG', value: "${env.DYNAMODB_IMAGE_TAG}"),
                      string(name: 'POSTGRES_IMAGE_TAG', value: "${env.POSTGRES_IMAGE_TAG}")
                    ], configuration.fscPropagate(), ""
                  )
                }

                if(env.GERRIT_PROJECT == 'canvas-lms' && git.changedFiles(dockerDevFiles, 'HEAD^')) {
                  echo 'adding Local Docker Dev Build'
                  buildStage.makeFromJob('Local Docker Dev Build', '/Canvas/test-suites/local-docker-dev-smoke', stages, buildParameters)
                }

                if(configuration.isChangeMerged()) {
                  timedStage('Dependency Check', stages, {
                    snyk("canvas-lms:ruby", "Gemfile.lock", "$PATCHSET_TAG")
                  })
                }

                def distribution = load 'build/new-jenkins/groovy/distribution.groovy'
                distribution.stashBuildScripts()

                distribution.addRSpecSuites(stages)
                distribution.addSeleniumSuites(stages)

                parallel(stages)
              }
            }
          }//protectedNode
        }//script
      }//steps
    }//environment
  }//stages
}//pipeline
