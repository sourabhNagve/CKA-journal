#!/bin/bash

echo "Setting up cluster environment..."

# 1. Create Namespaces
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: finance-system
---
apiVersion: v1
kind: Namespace
metadata:
  name: db-ops
EOF

# 2. Create the target Database Pod in finance-system
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: postgres-db
  namespace: finance-system
  labels:
    app: postgres
spec:
  containers:
  - name: db
    image: postgres:13-alpine
    env:
    - name: POSTGRES_PASSWORD
      value: "exam-secret"
EOF

# 3. Create ServiceAccount for the CronJob
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backup-sa
  namespace: db-ops
EOF

# 4. Create the broken PVC (References missing StorageClass)
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: db-ops
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: premium-bak
EOF

# 5. Create the Suspended CronJob
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: db-backup
  namespace: db-ops
spec:
  schedule: "* * * * *"
  suspend: true
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: backup-sa
          restartPolicy: OnFailure
          containers:
          - name: backup-worker
            image: bitnami/kubectl:latest
            command: 
            - /bin/sh
            - -c
            - |
              echo "Starting backup..."
              kubectl exec -n finance-system postgres-db -- echo "fake-db-dump-data" > /backup/db.sql
              if [ $? -eq 0 ]; then
                echo "Backup successful"
              else
                echo "Backup failed"
                exit 1
              fi
            volumeMounts:
            - name: backup-vol
              mountPath: /backup
          volumes:
          - name: backup-vol
            persistentVolumeClaim:
              claimName: backup-pvc
EOF

# Wait for postgres to be ready
echo "Waiting for postgres-db to start..."
kubectl wait --for=condition=Ready pod/postgres-db -n finance-system --timeout=60s

echo "Setup complete. The environment is now broken and ready for the exam scenario."