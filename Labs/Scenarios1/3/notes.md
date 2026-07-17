If a CronJob has suspend: true, Kubernetes stops creating new Jobs for that CronJob. Any Job that is already running is allowed to finish normally, but future scheduled runs are paused until you set suspend: false again.
What it means
The schedule is effectively paused.

No new Job objects are created at the next cron times.

Existing Jobs are not killed just because the CronJob is suspended.

Example
If your CronJob runs every minute and you set suspend: true at 4:00 PM:

the 4:01 PM run will not start,

the 4:02 PM run will not start,

but any Job already started before suspension can keep running.

Useful note
This is commonly used to temporarily disable backups, cleanup jobs, or maintenance jobs without deleting the CronJob definition