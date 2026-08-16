# Kubernetes CronJob Schedule

The schedule is written in **cron format** inside the CronJob manifest, under:

```yaml
spec:
  schedule:
```

It uses **five fields**:

```text
* * * * *
│ │ │ │ │
│ │ │ │ └── Day of week
│ │ │ └──── Month
│ │ └────── Day of month
│ └──────── Hour
└────────── Minute
```

## Example

```yaml
apiVersion: batch/v1
kind: CronJob

metadata:
  name: hello

spec:
  schedule: "*/5 * * * *"

  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: hello
              image: busybox
              command: ["sh", "-c", "date; echo hello"]

          restartPolicy: OnFailure
```

This runs the Job **every 5 minutes**.

---

## Common Examples

```text
* * * * *       → Every minute

0 * * * *       → At minute 0 of every hour

0 0 * * *       → Every day at midnight

*/5 * * * *     → Every 5 minutes

0 2 * * *       → Every day at 2:00 AM

30 1 * * *      → Every day at 1:30 AM
```

## Easy Way to Read It

```text
Minute   Hour   Day of Month   Month   Day of Week
  ↓       ↓          ↓           ↓          ↓
  *       *          *           *          *
```

So, if you want a Job to run **every day at 1:30 AM**:

```text
30 1 * * *
```

### Remember

```text
Minute → Hour → Day → Month → Weekday
```
