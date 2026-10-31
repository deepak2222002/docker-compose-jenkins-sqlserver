pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        COMPOSE_PROJECT_NAME = 'jobportal'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Deploy SQL Server and Initialize Database') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'sqlserver-sa',
                        usernameVariable: 'SA_USERNAME',
                        passwordVariable: 'SA_PASSWORD'
                    ),
                    usernamePassword(
                        credentialsId: 'db-remoteuser',
                        usernameVariable: 'DB_USERNAME',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    sh '''
                        set +x
                        set -e

                        if [ "$SA_USERNAME" != "sa" ]; then
                          echo "The sqlserver-sa Jenkins credential username must be sa."
                          exit 2
                        fi

                        # Export credentials for Compose interpolation without writing secrets to disk.
                        export MSSQL_SA_PASSWORD="$SA_PASSWORD"
                        export DB_USERNAME="$DB_USERNAME"
                        export DB_PASSWORD="$DB_PASSWORD"

                        docker --version
                        docker compose version
                        docker compose config --quiet
                        docker compose pull sqlserver

                        docker compose up -d sqlserver
                        docker compose ps

                        for attempt in $(seq 1 60); do
                          status=$(docker inspect --format='{{.State.Health.Status}}' sqlserver 2>/dev/null || true)
                          echo "SQL Server health: ${status:-starting} (attempt ${attempt}/60)"
                          if [ "$status" = "healthy" ]; then
                            break
                          fi
                          if [ "$attempt" -eq 60 ]; then
                            echo "SQL Server did not become healthy in time."
                            docker compose logs --tail=200 sqlserver
                            exit 1
                          fi
                          sleep 5
                        done

                        docker compose --profile init run --rm --no-deps sql-init
                        docker compose ps
                        docker compose logs --tail=100 sqlserver
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'SQL Server deployment and database initialization completed.'
        }
        failure {
            echo 'Deployment failed. Inspect the Jenkins console and run docker compose logs.'
        }
    }
}
