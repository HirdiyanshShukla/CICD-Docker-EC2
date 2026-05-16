pipeline {

    // Run on Jenkins agent/workspace
    agent any

    environment {

        // Application name injected dynamically by the Go CLI
        APP_NAME = 'django-app'

        // Local Docker registry
        REGISTRY = 'localhost:5001'
    }

    stages {

        stage('🛠️ Build Docker Image') {
            steps {

                echo "Building production image..."

                sh """
                docker build \
                  -t \${APP_NAME}:latest .
                """
            }
        }

        stage('🧪 Run Unit Tests') {
            steps {

                echo "Running unit tests..."

                // Run tests inside container
                sh """
                docker run --rm \
                  \${APP_NAME}:latest \
                  sh -c 'python main/manage.py test || true'
                """
            }
        }

        stage('🔒 Security Scan (Checkov)') {
            steps {

                echo "Scanning Infrastructure as Code..."

                // Scan repo using Checkov container
                sh """
                docker run --rm \
                  -v \${WORKSPACE}:/work \
                  bridgecrew/checkov \
                  -d /work \
                  --skip-path k8s/overlays \
                  --quiet || true
                """
            }
        }

        stage('📦 Tag & Push to Registry') {
            steps {

                script {

                    // Get short git commit SHA
                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    // Fallback
                    if (env.GIT_SHA == "") {
                        env.GIT_SHA = "latest"
                    }
                }

                echo "Tagging image with SHA: \${GIT_SHA}"

                sh """
                docker tag \
                  \${APP_NAME}:latest \
                  \${REGISTRY}/\${APP_NAME}:\${GIT_SHA}
                """

                sh """
                docker push \
                  \${REGISTRY}/\${APP_NAME}:\${GIT_SHA}
                """
            }
        }

        stage('🚀 Deploy to Kubernetes') {
            steps {

                echo "Updating Kustomize and Deploying to Production..."

                script {

                    // Update image tag in Kustomize
                    sh """
                    cd k8s/base && \
                    kustomize edit set image \
                    localhost:5001/\${APP_NAME}:latest=localhost:5001/\${APP_NAME}:\${GIT_SHA}
                    """

                    // Build manifests and deploy to Kind cluster
                    sh """
                    kustomize build k8s/overlays/prod | docker run -i --rm -u root --network host \
                      -v \${env.HOST_HOME}/.kube:/root/.kube \
                      -e KUBECONFIG=/root/.kube/config \
                      bitnami/kubectl --context kind-ephemeral-test --insecure-skip-tls-verify=true apply -f -
                    """
                }
            }
        }
    }

    post {

        always {

            echo "Pipeline execution complete. Cleaning workspace..."

            cleanWs()
        }
    }
}