 #!/bin/bash


if [ "$#" -eq  "0" ]; then
  echo "No arguments supplied. Please enter namespace to install Grafana-Agent"
  exit 1
fi

NAMESPACE=$1

echo "Installing Grafana-Agent to ${NAMESPACE} namespace"

MANIFEST_URL=https://raw.githubusercontent.com/grafana/agent/main/production/kubernetes/agent-bare.yaml /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/grafana/agent/release/production/kubernetes/install-bare.sh)" | kubectl apply -f -

cat <<'EOF' |

kind: ConfigMap
metadata:
  name: grafana-agent
apiVersion: v1
data:
  agent.yaml: |
    server:
      http_listen_port: 12345
    prometheus:
      wal_directory: /tmp/grafana-agent-wal
      global:
        scrape_interval: 15s
        external_labels:
          cluster: kubernetes 
      configs:
      - name: integrations
        remote_write:
        - url: YOUR_REMOTE_WRITE_URL
          #basic_auth:
          #  username: YOUR_REMOTE_WRITE_USERNAME
          #  password: YOUR_REMOTE_WRITE_PASSWORD
        scrape_configs:
        - job_name: integrations/kubernetes/cadvisor
          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
          kubernetes_sd_configs:
            - role: node
          metric_relabel_configs:
            - action: drop
              regex: container_([a-z_]+);
              source_labels:
                - __name__
                - image
            - action: drop
              regex: container_(network_tcp_usage_total|network_udp_usage_total|tasks_state|cpu_load_average_10s)
              source_labels:
                - __name__
          relabel_configs:
            - replacement: kubernetes.default.svc:443
              target_label: __address__
            - regex: (.+)
              replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor
              source_labels:
                - __meta_kubernetes_node_name
              target_label: __metrics_path__
          scheme: https
          tls_config:
              ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
              insecure_skip_verify: false
              server_name: kubernetes
        - job_name: integrations/kubernetes/kubelet
          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
          kubernetes_sd_configs:
            - role: node
          relabel_configs:
            - replacement: kubernetes.default.svc:443
              target_label: __address__
            - regex: (.+)
              replacement: /api/v1/nodes/$1/proxy/metrics
              source_labels:
                - __meta_kubernetes_node_name
              target_label: __metrics_path__
          scheme: https
          tls_config:
              ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
              insecure_skip_verify: false
              server_name: kubernetes

EOF
(kubectl apply -n $NAMESPACE -f -)
