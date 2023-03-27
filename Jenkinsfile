@Library('mss-sharedlibrary') _

pipeline {
  //agent any
   agent{
      label "nodemvn"
       }

       options {
         buildDiscarder logRotator( artifactDaysToKeepStr: '1', artifactNumToKeepStr: '3', daysToKeepStr: '1', numToKeepStr: '3')
         timestamps()
         //skipDefaultCheckout(true)
        }

     parameters {
          choice choices: ['main','mss-prod', 'mss-warmart-prod', 'mss-mvn-demo', 'slack_success_failed_demo', 'lab_mutation_Test', 'walmart-dev-mss', 'dependencyCheckTrivyOpenContest'], description: 'This is choice paramerized job', name: 'BranchName'
          string defaultValue: 'Eghosa DevOps', description: 'please developer select the person\' name', name: 'personName'
        }

  tools{
      maven 'demo-maven:3.8.6'
      }

 environment {
            DEPLOY = "${env.BRANCH_NAME == "python-dramed" || env.BRANCH_NAME == "master" ? "true" : "false"}"
            NAME = "${env.BRANCH_NAME == "python-dramed" ? "example" : "example-staging"}"
            VERSION = "${env.BUILD_ID}"
            REGISTRY = 'eagunuworld/java-web-app'
            imageName = "eagunuworld/java-web-app:${BUILD_ID}"
            REGISTRY_CREDENTIAL = 'eagunuworld_dockerhub_creds'
            deploymentName = "mss-prod-pod"
            conName = "mss-mvn-con"
            svcName = "mss-mvn-svc"
            svcPort = "30008"
            jenkinsURL = "http://34.174.110.253"
            mssNode = "http://34.174.110.253"
          }

  stages {
    stage('Build Artifact - Maven') {
      steps {
         //cleanWs()
        sh "mvn clean package -DskipTests=true"
        archiveArtifacts 'target/*.war' 
      }
    }

    stage('SonarQube - SAST') {
      steps {
        withSonarQubeEnv('sonarQube') {
          sh "mvn clean package sonar:sonar -Dsonar.projectKey=mss-warmart-prod -Dsonar.host.url=http://34.125.191.177:9000 -Dsonar.login=sqp_0da2b86135cf6f23388b6642a6aa68d64f8ac183"
         }
        // timeout(time: 2, unit: 'MINUTES') {
        //   script {
        //     waitForQualityGate abortPipeline: true
        //   }
        // }
      }
    }

   stage('CodesVulnerabilityScanning') {    //(Pit mutation) is a plugin in jenkis and plugin was added in pom.xml line 68
      steps {
         parallel(
               "PitMutationTestReport": {
                    sh "kubectl get po -A"  //section 3 video
                  },
                  "DependencyCheckReport": {
                      sh "ls -lart"    //OWASP Dependency check plugin is required via jenkins
                   },
                 "EnvironmentVariables": {
                  sh "printenv"
               }
             )
         }
      }

  stage('ScanningBasedPushImage') {  
      steps {
         parallel(
               "ScanningAppImage": {
                 withCredentials([string(credentialsId: 'eagunuworld_dockerhub_creds', variable: 'eagunuworld_dockerhub_creds')])  {
                   sh "docker login -u eagunuworld -p ${eagunuworld_dockerhub_creds} "
                   sh 'docker build -t ${REGISTRY}:${VERSION} .'
                }
                sh 'docker push ${REGISTRY}:${VERSION}' 
               },
                "BasedImage": {
                sh "sudo rm -rf trivy"
                }
             )
         }
      }

  //  stage('Push Docker Image To DockerHub') {
  //       steps {
  //           withCredentials([string(credentialsId: 'eagunuworld_dockerhub_creds', variable: 'eagunuworld_dockerhub_creds')])  {
  //             sh "docker login -u eagunuworld -p ${eagunuworld_dockerhub_creds} "
  //             sh 'docker build -t ${REGISTRY}:${VERSION} .'
  //               }
  //               sh 'docker push ${REGISTRY}:${VERSION}'
  //           }
  //         }

    stage('ManifestK8SVulnerabilitYScanning') {  
      steps {
         parallel(
              //  "ScanningAppImage": {
              //       sh "bash trivy-k8s-scan.sh" 
              //     },
              //     "ScanningDeploymentFile": {
              //       sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego mss-north-west-deploy.yml'
              //      },
              //     //  "BasedImage": {
              //     //   sh "docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile"
              //     //  },
              //    "kubesec Scannning": {
              //     sh 'bash kubesec-scan.sh'
              //   },
                "Master": {
               sh "bash cis-benchmark-master.sh"
              },
              "Etcd": {
               sh "bash cis-benchmark-etcd.sh"
             },
             "Kubelet": {
              sh "bash cis-benchMark-kubelet.sh"
             }
           )
         }
      }

    // stage('comSecretMongodb') {
    //   steps {
    //     parallel(
    //       "configMap": {
    //           sh "kubectl apply -f mss-north-west-cm.yml"
    //         },
    //       "creatNS": {
    //           sh "kubectl apply -f  mss-north-ns.yml"
    //       },
    //       "createSecret": {
    //           sh "kubectl apply -f mss-north-west-secret.yml"
    //       }
    //     )
    //   }
    // }

    stage('PleaseApprove West-Prod?') {
      steps {
        timeout(time: 2, unit: 'DAYS') {
          input 'Do you want to Approve  West Production Environment/Namespace Deployment?'
        }
      }
    }

 stage('west-prod') {
      steps {
        parallel(
          "Deployment": {
              sh "sed -i 's#replace#${REGISTRY}:${VERSION}#g' mss-west-deploy.yml"
              sh "kubectl apply -f mss-west-deploy.yml"
            },
          "create-svcs": {
            sh "kubectl apply -f mss-north-svc.yml"
          }
        )
      }
    }

   stage('RemoveResources') {  
      steps {
         parallel(
               "KillProcesses": {
                    sh "printenv" 
                  },
                 "RemoveDockerImages": {
                  sh 'docker rmi  $(docker images -q)'
                },
                 "Display mss-warmart deploy": {
               sh 'kubectl -n mss-prod get svc,po'
              }
             )
         }
      }

  } // pipeline stages end here 
   post {
      //   always {
      //   junit 'target/surefire-reports/*.xml'
      //   jacoco execPattern: 'target/jacoco.exec'
      //   pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
      //   dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
      //  }
      success {
      script {
        /* Use slackNotifier.groovy from shared library and provide current build result as parameter */  
        env.failedStage = "none"
        env.emoji = ":white_check_mark: :tada: :thumbsup_all:"
        slackcodenotifications currentBuild.result
      }
    }
  }
}
