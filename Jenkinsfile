// Uses Declarative syntax to run commands inside a container.
pipeline {
    agent {
        kubernetes {
            yaml ''' 
apiVersion: v1
kind: Pod
metadata:
  name: my-agent
spec:
  securityContext:
    runAsUser: 0
  containers:
  - name: my-agent
    image: ubuntu
    command: sleep
    args:
      - infinity
    volumeMounts:
    - name: dockersock
      mountPath: /var/run/docker.sock
  volumes:
    - name: dockersock
      hostPath:
        path: /var/run/docker.sock
'''
        }
    }
    stages {
        stage('Checkout the SCM') {
            steps {
                checkout([$class: 'GitSCM', branches:[[name: '*/master']], userRemoteConfigs: [[url: 'https://github.com/lokeshb003/Springboot-app']]])
            }
        }
        stage('Install Maven and Neccessary Packages in the Container') {
            steps {
                sh 'apt-get update -y && apt-get install -y systemd maven docker.io && apt-get install systemctl -y'
            }
        }
        stage('Compile the Maven Application') {
            steps {
                sh 'mvn compile'
            }
        }
        stage('Build Springboot Application') {
            steps {
                sh 'mvn clean package -DskipTests=true'
            }
        }
        stage('Test the Springboot Application') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    jacoco(execPattern: '**/build/jacoco/*.exec',classPattern: '**/build/classes/java/main',sourcePattern: '**/src/main')
                }
            }
        }
        stage('PIT Mutation Testing') {
            steps {
                sh 'mvn org.pitest:pitest-maven:mutationCoverage'
            }
            post {
                always {
                    pitmutation killRatioMustImprove: false, minimumKillRatio: 50.0, mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
                }
            }
        }
        stage('SonarQube SAST Test') {
            steps {
                sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=basic-pipeline-jenkins -Dsonar.projectName=basic-pipeline-jenkins -Dsonar.host.url=http://194.195.255.233:9000 -Dsonar.token=sqp_8b7ba65445f0cd294e9b6848263af7ae69c2cc21'
            }
        }
        stage('OWASP Dependency Check') {
            steps {
                sh 'mvn dependency-check:check'
                dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
            }
        }
        stage('Deploy to Nexus Repository Manager') {
            steps {
                sh 'mvn clean deploy -DaltDeploymentRepository=nexus-snapshots::default::https://nexus.lokii.tech/repository/nexus-snapshots/'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker login -u ${DOCKERHUB_USER} -p ${DOCKERHUB_PASS}'
                script {
                    def app = docker.build('lokeshb003/basic-pipeline:latest')
                    app.push()
                }
            }
        }
        stage('Trivy Image Scanning') {
            steps {
                sh 'apt-get install wget apt-transport-https gnupg lsb-release -y'
                sh 'wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null'
                sh 'echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list'
                sh 'apt-get update && apt-get install trivy -y'
                sh 'trivy image lokeshb003/basic-pipeline:latest'
            }
        }
    }
}
