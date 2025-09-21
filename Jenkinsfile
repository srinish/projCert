pipeline {
  agent any
  environment {
    PROJECT     = "devopscertification-472014"
    ZONE        = "us-central1-a"
    TEST_PREFIX = "test-server"
    GCP_SA_CRED = "gcp-sa-key"
    SSH_CRED_ID = "jenkins-ssh-key"
    STARTUP_PATH = "${WORKSPACE}/jenkins-slave-startup.sh"
  }
  stages {
    stage('Auth to GCP & create startup script') {
      steps {
        withCredentials([file(credentialsId: env.GCP_SA_CRED, variable: 'GCP_SA_JSON')]) {
          sh '''
            cp "${GCP_SA_JSON}" /tmp/gcp-sa.json
            chmod 600 /tmp/gcp-sa.json
            gcloud auth activate-service-account --key-file=/tmp/gcp-sa.json
            gcloud config set project ${PROJECT}

            # Create startup script
            cat > "${STARTUP_PATH}" <<'SCRIPT'
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y python3 python3-pip openssh-server git sudo
if ! id -u jenkins >/dev/null 2>&1; then
    useradd -m -s /bin/bash jenkins
    echo "jenkins ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jenkins
fi
mkdir -p /home/jenkins/.ssh
chown -R jenkins:jenkins /home/jenkins/.ssh
chmod 700 /home/jenkins/.ssh
SCRIPT
            chmod 700 "${STARTUP_PATH}"
          '''
        }
      }
    }

    stage('Provision Test Instance') {
      steps {
        script {
          def pubKey = sh(script: 'cat /var/lib/jenkins/.ssh/id_rsa.pub', returnStdout: true).trim()
          def instanceName = "${TEST_PREFIX}-${BUILD_NUMBER}"
          sh """
            gcloud compute instances create "${instanceName}" \
              --zone="${ZONE}" \
              --machine-type=e2-medium \
              --image-project=ubuntu-os-cloud \
              --image-family=ubuntu-2204-lts \
              --metadata-from-file=startup-script="${STARTUP_PATH}" \
              --metadata="ssh-keys=jenkins:${pubKey}" \
              --tags=test-server \
              --quiet
            TEST_IP=\$(gcloud compute instances describe "${instanceName}" --zone="${ZONE}" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
            echo "\${TEST_IP}" > "${WORKSPACE}/TEST_IP.txt"
            echo "Test server IP: \${TEST_IP}"
          """
        }
      }
    }

  stage('Wait for SSH') {
      steps {
        script {
          def ip = readFile('TEST_IP.txt').trim()
          echo "Waiting for SSH on ${ip}..."
          def ready = false
          for (int i = 0; i < 30; i++) {
            def status = sh(script: "nc -z -w 5 ${ip} 22 && echo OK || echo NO", returnStdout: true).trim()
            if (status == "OK") {
              ready = true
              break
            }
            sleep 5
          }
          if (!ready) {
            error("❌ SSH did not become available on ${ip}")
          }
          echo "✅ SSH is ready on ${ip}"
        }
      }
    }
  }

  post {
    success {
            script {
                def testIp = readFile('TEST_IP.txt').trim()
                echo "Passing TEST_IP=${testIp} to Job1"
                build job: 'Job1-Install-Puppet-Agent',
                      parameters: [string(name: 'TEST_IP', value: testIp)]
                      wait: false
            }
        }
       failure {
            echo "Job2 failed, cleaning container..."
            build job: 'Job4-Cleanup-Container-on-Failure',
                     parameters: [string(name: 'TEST_IP', value: params.TEST_IP)]
        }
  }
}
