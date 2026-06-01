pipeline {
    agent any
    
    environment {
        // A Jenkins Credentials-ből biztonságosan behúzzuk az AWS kulcsokat
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION    = 'eu-central-1'
    }

    stages {
        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform init'
                sh 'terraform apply -auto-approve'
                // Kimentjük az új AWS gép IP címét egy változóba az Ansible számára
                script {
                    env.EC2_PUBLIC_IP = sh(script: 'terraform output -raw ec2_public_ip', returnStdout: true).trim()
                }
            }
        }

        stage('Ansible Configuration') {
            steps {
                // Megvárjuk, amíg az AWS gép SSH-ja teljesen elindul
                sh 'sleep 30'
                // Elindítjuk az Ansible-t, átadva neki a dinamikus IP-t és az SSH kulcsot
                sh "ansible-playbook -i '${env.EC2_PUBLIC_IP},' -u ubuntu --private-key ~/.ssh/id_rsa playbook.yml"
            }
        }
    }
    
    post {
        cleanWs() // A build végén kitakarítjuk a munkakörnyezetet
    }
}