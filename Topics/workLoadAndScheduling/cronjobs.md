The schedule is written in cron format inside the CronJob manifest, under spec.schedule. It uses five fields:


Examples
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

* * * * * → every minute.

0 * * * * → at minute 0 of every hour.

0 0 * * * → every day at midnight.

*/5 * * * * → every 5 minutes.

0 2 * * * → every day at 2:00 AM.

Easy way to read it
The fields mean:

first = minutes.

second = hours.

third = day of month.

fourth = month.

fifth = day of week.

So if you want a job every day at 1:30 AM, you would write:

30 1 * * *

