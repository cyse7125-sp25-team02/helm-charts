#!/bin/bash

set -e

# Logging function
log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message"
}

# Check if a command exists
check_command() {
    if ! command -v "$1" &>/dev/null; then
        log "ERROR" "$1 is not installed or not found in PATH"
        exit 1
    fi
}

# Decrypt SOPS values
decrypt_sops_values() {
    local chart_dir="$1"
    local sops_file="$2"
    local output_file="$3"

    if [ ! -f "$chart_dir/$sops_file" ]; then
        log "ERROR" "SOPS file not found: $chart_dir/$sops_file"
        exit 1
    fi

    log "INFO" "Decrypting SOPS file: $chart_dir/$sops_file"
    sops --decrypt "$chart_dir/$sops_file" >"$chart_dir/$output_file" || {
        log "ERROR" "Failed to decrypt SOPS file"
        exit 1
    }
    log "INFO" "Decrypted values written to: $chart_dir/$output_file"
}

# Perform Helm install
helm_install() {
    local chart_dir="$1"
    local release_name="$2"
    local values_file="$3"

    if [ ! -f "$chart_dir/$values_file" ]; then
        log "ERROR" "Values file not found: $chart_dir/$values_file"
        exit 1
    fi

    log "INFO" "Installing Helm chart in $chart_dir with release $release_name"

    helm install "$release_name" "$chart_dir" --values="$chart_dir/$values_file" || {
        log "ERROR" "Helm install -failed"
        exit 1
    }
    log "INFO" "Helm chart $release_name installed successfully"
}

# Process Cert Manager chart
process_cert_manager_chart() {
    local project_root="$1"
    local cert_manager_folder="cert-manager"
    local release_name="cert-manager"
    local chart_dir="$project_root/$cert_manager_folder"

    if [ ! -d "$chart_dir" ]; then
        log "ERROR" "Chart folder not found: $chart_dir"
        exit 1
    fi

    log "INFO" "Processing Cert Manager chart in $chart_dir"

    # Decrypt SOPS values
    decrypt_sops_values "$chart_dir" "values.enc.yaml" "values.yaml"

    helm dependency update "$chart_dir" || {
        log "ERROR" "Failed to update Helm dependencies"
        exit 1
    }
    log "INFO" "Helm dependencies updated successfully"

    # Install Helm chart
    helm_install "$chart_dir" "$release_name" "values.yaml"
}

# Process API Server chart
process_api_server_chart() {
    local project_root="$1"
    local api_server_folder="api-server"
    local release_name="api-server"
    local chart_dir="$project_root/$api_server_folder"

    if [ ! -d "$chart_dir" ]; then
        log "ERROR" "Chart folder not found: $chart_dir"
        exit 1
    fi

    log "INFO" "Processing API Server chart in $chart_dir"

    # Decrypt SOPS values
    decrypt_sops_values "$chart_dir" "values.enc.yaml" "values.yaml"

    # Install Helm chart
    helm_install "$chart_dir" "$release_name" "values.yaml"
}

# Process DB Backup Operator chart
process_db_backup_operator_chart() {
    local project_root="$1"
    local db_backup_folder="db-backup-operator"
    local release_name="db-backup-operator"
    local chart_dir="$project_root/$db_backup_folder"

    if [ ! -d "$chart_dir" ]; then
        log "ERROR" "Chart folder not found: $chart_dir"
        exit 1
    fi

    log "INFO" "Processing DB Backup Operator chart in $chart_dir"

    # Decrypt SOPS values
    decrypt_sops_values "$chart_dir" "values.enc.yaml" "values.yaml"

    # Install Helm chart
    helm_install "$chart_dir" "$release_name" "values.yaml"
}

# Process Trace Processor chart
process_trace_processor_chart() {
    local project_root="$1"
    local trace_processor_folder="trace-processor"
    local release_name="trace-processor"
    local chart_dir="$project_root/$trace_processor_folder"

    if [ ! -d "$chart_dir" ]; then
        log "ERROR" "Chart folder not found: $chart_dir"
        exit 1
    fi

    log "INFO" "Processing Trace Processor chart in $chart_dir"

    # Decrypt SOPS values
    decrypt_sops_values "$chart_dir" "values.enc.yaml" "values.yaml"

    # Install Helm chart
    helm_install "$chart_dir" "$release_name" "values.yaml"
}

# Process Kafka chart
process_kafka_chart() {
    local project_root="$1"
    local kafka_folder="kafka"
    local release_name="pdf-upload"
    local chart_dir="$project_root/$kafka_folder"

    if [ ! -d "$chart_dir" ]; then
        log "ERROR" "Chart folder not found: $chart_dir"
        exit 1
    fi

    log "INFO" "Processing Kafka chart in $chart_dir"

    # Decrypt SOPS values
    decrypt_sops_values "$chart_dir" "values.enc.yaml" "values.yaml"

    # Install Helm chart
    helm_install "$chart_dir" "$release_name" "values.yaml"

    # Create Kafka topic
    create_kafka_topic "$release_name"
}


# Create Kafka topic with retry
create_kafka_topic() {
    local release_name="$1"
    local max_retries=10
    local retry_interval=10
    local attempt=1
    local topic_command="kubectl exec -it pdf-upload-kafka-broker-0 -n kafka -- /opt/bitnami/kafka/bin/kafka-topics.sh --create --topic $release_name --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1"

    log "INFO" "Attempting to create Kafka topic"
    while [ $attempt -le $max_retries ]; do
        if $topic_command; then
            log "INFO" "Kafka topic created successfully"
            return 0
        else
            log "WARNING" "Attempt $attempt/$max_retries failed to create Kafka topic"
            if [ $attempt -eq $max_retries ]; then
                log "ERROR" "Max retries reached. Failed to create Kafka topic."
                exit 1
            fi
            log "INFO" "Retrying in $retry_interval seconds..."
            sleep $retry_interval
            ((attempt++))
        fi
    done
}

# Main function
main() {
    local project_root
    project_root="$(pwd)"

    log "INFO" "Starting deployment from project root: $project_root"

    # Check required commands
    check_command sops
    check_command helm
    check_command kubectl

    process_cert_manager_chart "$project_root"

    log "INFO" "Waiting 30 seconds for Cert-Manager certificates to be ready"
    sleep 30

    process_kafka_chart "$project_root"
    process_api_server_chart "$project_root"
    process_db_backup_operator_chart "$project_root"
    process_trace_processor_chart "$project_root"

    log "INFO" "Kafka chart deployment completed successfully"
}

# Execute main
main
