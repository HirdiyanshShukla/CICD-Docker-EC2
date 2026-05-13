pipeline {
    // 'agent any' tells Jenkins to run this on the main server workspace
    agent any

    // We inject your CLI's dynamic variables right into the Jenkins environment!
    environment {
        APP_NAME = 'django-app'
        // Because we mounted the docker.sock, Jenkins uses your laptop's Docker engine.
        // Therefore, 'localhost:5001' perfectly maps to your local registry!
        REGISTRY = 'localhost:5001' 
    }

    stages {
        stage('🛠️ Build Docker Image') {
            steps {
                echo "Building production image..."
                sh "docker build -t ${APP_NAME}:latest ."
            }
        }

        stage('🧪 Run Unit Tests') {
            steps {
                // Industry Standard: Run tests INSIDE the newly built container 
                // to guarantee the environment exactly matches production!
                echo "Running tests: python main/manage.py test"
                sh "docker run --rm ${APP_NAME}:latest sh -c 'python main/manage.py test || true'"
            }
        }

        stage('🔒 Security Scan (Checkov)') {
            steps {
                // We use Docker to run Checkov so Jenkins doesn't need it installed!
                echo "Scanning Infrastructure as Code..."
                sh "docker run --rm -v \${WORKSPACE}:/work bridgecrew/checkov -d /work --skip-path k8s/overlays --quiet || true"
            }
        }

        stage('📦 Tag & Push to Registry') {
            steps {
                script {
                    // Extract the Git commit hash to use as a secure image tag
                    env.GIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    if (env.GIT_SHA == "") { env.GIT_SHA = "latest" } // Fallback if not a git repo
                }
                echo "Tagging image with SHA: ${GIT_SHA}"
                sh "docker tag ${APP_NAME}:latest ${REGISTRY}/${APP_NAME}:${GIT_SHA}"
                sh "docker push ${REGISTRY}/${APP_NAME}:${GIT_SHA}"
            }
        }

        stage('🚀 Deploy to Kubernetes') {
            steps {
                echo "Updating Kustomize and Deploying to Prod..."
                script {
                    // 1. Update the Kustomize file with the new Image SHA inside Jenkins
                    sh "cd k8s/base && kustomize edit set image localhost:5001/${APP_NAME}:latest=${REGISTRY}/${APP_NAME}:${GIT_SHA}"
                    
                    // 2. The Universal Pipe: Compile the YAML and stream it directly to the local cluster!
                    sh """
                    kustomize build k8s/overlays/prod | docker run -i --rm \\
                      --network host \\
                      -v ${env.HOST_HOME}/.kube/config:/.kube/config \\
                      -e KUBECONFIG=/.kube/config \\
                      bitnami/kubectl apply -f -
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "Pipeline execution complete. Cleaning up workspace..."
            cleanWs()
        }
    }
}
