pipeline {
    agent any

    // 1. Itt adjuk meg a paramétert (legördülő menü a Jenkins felületén)
    parameters {
        choice(
            name: 'MUV_ACTION', 
            choices: ['apply', 'destroy'], 
            description: 'Válaszd ki, hogy felépíteni (apply) vagy törölni (destroy) akarod a labort!'
        )
    }
    
    environment {
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

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        // 2. Ez a fázis CSAK akkor fut le, ha az 'apply' opciót választottad
        stage('Terraform Apply') {
            when {
                expression { params.MUV_ACTION == 'apply' }
            }
            steps {
                sh 'terraform apply -auto-approve'
                script {
                    env.EC2_PUBLIC_IP = sh(script: 'terraform output -raw ec2_public_ip', returnStdout: true).trim()
                }
            }
        }

        // 3. Ez is CSAK 'apply' esetén fut le
        stage('Ansible Configuration') {
            when {
                expression { params.MUV_ACTION == 'apply' }
            }
            steps {
                sh 'sleep 30'
                sh "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${env.EC2_PUBLIC_IP},' -u ubuntu --private-key ~/.ssh/id_rsa playbook.yml"
            }
        }

        // 4. Ez a fázis CSAK akkor fut le, ha a 'destroy' opciót választottad
        stage('Terraform Destroy') {
            when {
                expression { params.MUV_ACTION == 'destroy' }
            }
            steps {
                sh 'terraform destroy -auto-approve'
            }
        }
    }
    
    post {
        always {
            echo "A választott művelet (${params.MUV_ACTION}) sikeresen véget ért."
        }
    }
}