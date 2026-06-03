# openstack-automated-lab
 AWS-Jenkins-Ansible OpenStack Lab Automation

This project implements a fully automated OpenStack laboratory environment deployed on AWS using a Jenkins pipeline. It combines **Infrastructure as Code (IaC)** principles with Terraform and configuration management via Ansible.

## Architecture and Workflow

The environment automation consists of three core components:
1. **Jenkins Pipeline (`Jenkinsfile`):** Orchestrates the entire workflow, manages user parameters, and handles AWS authentication credentials.
2. **Terraform:** Provisions the required AWS infrastructure (EC2 instance, Security Group, and SSH Key Pair).
3. **Ansible Playbook (`playbook.yml`):** Configures the newly provisioned Ubuntu server and installs the MicroStack (OpenStack) environment.

---

## File Breakdown

### 1. Jenkins Pipeline (`Jenkinsfile`)
The CI/CD process utilizes a declarative Jenkins pipeline that supports two main operations via the `MUV_ACTION` parameter:
* **`apply`**: Provisions the infrastructure and automatically triggers the software configuration phase.
* **`destroy`**: Tears down the entire AWS environment to prevent unnecessary hosting costs.

**Key Pipeline Stages:**
* **Git Checkout:** Pulls the source code from the repository.
* **Terraform Init:** Initializes the Terraform working directory and downloads the required AWS provider.
* **Terraform Apply (Executed on `apply`):** Spins up the EC2 instance and captures its public IP into an environment variable (`EC2_PUBLIC_IP`).
* **Ansible Configuration (Executed on `apply`):** Waits for 30 seconds (ensuring the SSH daemon is ready) and runs the configuration playbook against the target server.
* **Terraform Destroy (Executed on `destroy`):** Safely destroys all AWS infrastructure managed by this Terraform state.

### 2. Terraform Configuration
The Terraform script provisions resources in the `eu-central-1` (Frankfurt) region:
* **`aws_key_pair`**: Dynamically reads and registers your local machine's public SSH key (`/Users/markosz/.ssh/id_rsa.pub`) to grant secure administrative access.
* **`aws_security_group`**: Creates a security group allowing inbound SSH traffic (port 22) from anywhere (`0.0.0.0/0`) and permits unrestricted outbound traffic.
* **`aws_instance`**: Launches an Ubuntu server utilizing a `t3.large` instance type with 30 GB of `gp3` root storage, which provides sufficient resources to host MicroStack.

### 3. Ansible Playbook (`playbook.yml`)
Once the instance is running, Ansible handles the operating-system-level configuration running with elevated privileges (`become: yes`):
1. **System Update:** Executes system upgrades using `apt update & upgrade`.
2. **Reboot:** Restarts the machine to ensure any newly installed kernel updates are applied.
3. **MicroStack Installation:** Installs MicroStack via the Snap package manager with `--beta` and `--devmode` flags.
4. **Initialization:** Runs the `microstack init` script asynchronously (in the background) to prevent the pipeline from blocking or timing out.
5. **API Verification:** Monitors the OpenStack Keystone identity service on port 5000, waiting until the service becomes responsive.
6. **Convenience Setup:** Appends an `openstack` command alias to the `ubuntu` user's `.bashrc` file for easier CLI interactions.

---

## Prerequisites

To run this pipeline successfully, ensure your Jenkins environment meets the following requirements:
1. **Local SSH Key:** The Jenkins runner node or user must have a valid public key located at `/Users/markosz/.ssh/id_rsa.pub` (or modify this path in the Terraform script to match your setup).
2. **Jenkins Credentials:** Configure two Secret Text or Environment Variable credentials within Jenkins:
    * `AWS_ACCESS_KEY_ID`
    * `AWS_SECRET_ACCESS_KEY`
3. **Required CLI Tools:** The Jenkins execution node must have both `terraform` and `ansible-playbook` installed and available in its `PATH`.

## Usage

1. Open your Jenkins Dashboard and select this project.
2. Click on **Build with Parameters**.
3. Choose the desired action from the **MUV_ACTION** dropdown menu:
    * `apply`: Spin up and configure a fresh lab environment.
    * `destroy`: Teardown and clean up all allocated AWS resources.
4. Click **Build** to trigger the automation workflow.