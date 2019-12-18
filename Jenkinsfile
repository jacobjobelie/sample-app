pipeline {

  environment {
    PROJECT = "REPLACE_WITH_YOUR_PROJECT_ID"
    APP_NAME = "gceme"
    FE_SVC_NAME = "${APP_NAME}-frontend"
    CLUSTER = "jenkins-cd"
    CLUSTER_ZONE = "us-east1-d"
    IMAGE_TAG = "gcr.io/${PROJECT}/${APP_NAME}:${env.BRANCH_NAME}.${env.BUILD_NUMBER}"
    JENKINS_CRED = "${PROJECT}"
    DOCKER_REG = "samuelrad/first"
    DOCKER_REG_CRED = "dockerhub"
  }

  agent {
    kubernetes {
          label 'sample-app'
          defaultContainer 'jnlp'
          yaml """
    apiVersion: v1
    kind: Pod
    metadata:
    labels:
      component: ci
    spec:
      # Use service account that can deploy to all namespaces
      serviceAccountName: cd-jenkins
      containers:
      - name: node
        image: node:12.14.0-alpine
        command:
        - cat
        tty: true
      - name: gcloud
        image: gcr.io/cloud-builders/gcloud
        command:
        - cat
        tty: true
      - name: kubectl
        image: gcr.io/cloud-builders/kubectl
        command:
        - cat
        tty: true
      - name: docker
        image: docker:1.11
        command: ['cat']
        tty: true
        volumeMounts:
        - name: dockersock
          mountPath: /var/run/docker.sock
      volumes:
      - name: dockersock
        hostPath:
          path: /var/run/docker.sock
    """
    }
  }
  stages {
    stage('Test') {
      steps {
        container('node') {
          sh 'node --version'
        }
      }
    }
    stage("Build image") {
      steps {
        container('docker') {
          withCredentials([[$class: 'UsernamePasswordMultiBinding',
          credentialsId: 'docker_samuelrad',
          usernameVariable: 'DOCKER_HUB_USER',
          passwordVariable: 'DOCKER_HUB_PASSWORD']]) {
          sh """
            docker login -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASSWORD}
            docker build -t ${env.DOCKER_REG}:${env.BUILD_NUMBER} ."
            """
          }
        }
      }
    }
  }
}
