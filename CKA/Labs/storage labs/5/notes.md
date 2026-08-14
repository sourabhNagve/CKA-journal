  # you can add prefix like this if multiple secrets are using the same keys
  envFrom:
        - prefix: PRI_
          secretRef:
            name: db-creds-primary
        - prefix: REP_
          secretRef:
            name: db-creds-replica