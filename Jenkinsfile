pipeline {
    agent any

    parameters {
        string(name: 'BRANCH', defaultValue: 'main')
        string(name: 'TAG', defaultValue: '')
    }

    environment {
        APP_GIT = "https://github.com/zhang3800/solo.git"
    }

    stages {

        stage('拉代码') {
            steps {
                deleteDir()
                git branch: "${params.BRANCH}",
                    url: "${APP_GIT}"
            }
        }

        stage('Maven构建') {
            steps {
                sh """
                    source scripts/config.sh
                    bash scripts/build.sh
                """
            }
        }

        stage('构建镜像') {
            steps {
                sh """
                    source scripts/config.sh
                    bash scripts/docker.sh ${params.TAG}
                """
            }
        }

        stage('部署') {
            steps {
                sh """
                    source scripts/config.sh
                    bash scripts/deploy.sh
                """
            }
        }
    }
}
