apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${cluster_ca_certificate}
    server: https://${endpoint}
  name: gke
contexts:
- context:
    cluster: gke
    user: gke
  name: gke
current-context: gke
kind: Config
preferences: {}
users:
- name: gke
  user:
    auth-provider:
      config:
        access-token: ${token}
      name: gcp
