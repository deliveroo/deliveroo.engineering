# Alerting guidelines

Inspired by these [alerting guidelines](https://docs.google.com/document/d/199PqyG3UsyXlwieHaqbGiWVa8eMWi8zzAn0YfcApr8Q/edit) written by an ex-Site Reliability Engineer at Google.

## What is an alert?

An alert is a real, actionable, urgent message sent to an engineer or a group of engineers via a communication channel (email, sms, phone call push notification, Slack notification,...) that requires attention and should be responded to urgently.

* Real – the alert cannot be ignored; it’s signal, not noise
* Actionable – what action can be taken when the alert is raised?
* Happy path – a set of actions that are important for a visitor to book a holiday (register, send an enquiry,...)

## What is a notification?

Notification is a message that does not require immediate attention. It reflects a system state and serves as a heads-up – gives you a chance to prevent an alert.
Messages are not sent to duty engineers but are just pushed to #notification channel.

Example: Disk space on a web worker is < 5 GB.

## How to setup an alert?

### Check your alert is valid

Why do we need the alert? A good answer would be: "Because if we don't alert on `<insert your reason here>` users won’t be able to book and we are going to lose money!"

Another scenario worth considering: "Imagine it’s Saturday night and your feature is breaking. Do you need to wake up the Duty engineer or can we live with it being broken until Monday morning?"

Last but not least: "Is the step you want to monitor on the happy path? Should it be?"

### Alert on symptoms, not causes

Symptom based alerting is focused around creating rules and conditions that mimic those of an end user. Setting the alert on the symptom allows you to catch multiple causes with a single alert rule.

Users care about a feature not working not why it’s not working – users care about a symptom not cause. For example a user might be upset when:
* Page loads are slow
* There are errors on page or page does not load completely
* Invalid data is displayed
* “A button is not working”

Example:
The end user does not care about MySQL server being unreachable. She cares about not being able to view a property or sign in.

Example 2: A less extreme example would be users not receiving transactional emails. There might be multiple causes why (code error, delayed jobs not processing, Mandrill not accessible, ...). Alerting on cause would mean setting up alerts for each cause.

### Test on staging

Good developers test on staging. Without going to much into details;

New Relic has staging policy group for applications and transaction set up - make sure your monitor is included in one of them. When an alert is triggered you'll be notified to Slack `#staging-alert` channel.

Similar, testing DataDog monitors on staging requires selecting staging hosts and annotating monitor message with @slack-staging-alerts.

### Peer review for all alerts

Every added alert should be reviewed by another engineer. Think of it as a PR for the new alert. This ensures knowledge is shared and an extra pair of eyes may spot some obvious errors.

## Tools and services

Quick overview of the tools we use to detect abnormal behaviour and notify on alerts.

### Monitoring the alert

After the alert has been put to production you have ownership of it. This means you have to track its accountability. When it’s raised you should answer these questions:
Is the alert catching the symptom?
Was the alert raised in timely fashion?
Was it a genuine alert (signal) and not a fake one (noise)?
Did you take any actions in order to fix it?

If all above questions are answered affirmatively, congratulations! If not, iterate!

### New Relic (NR)

Pros:
* Setting up response times and errors per user action (i.e. high error rate on user registration)
* Pinging an application (pingdom-like health check, checks if the application is online and responds with success)
* Tracking response times on the web server
* Application and transaction policies to segment applications & transactions into appropriate groups, i.e. API, End User, Admin.

Cons:
* Very sensitive when monitoring end user response times (slow clients)
* Possible false alerts when low traffic (i.e. 3 requests in last 5 minutes, ⅔ were errors => 66% error rate)

### DataDog (DD)

Pros:
* Background process healthcheck (i.e. scheduler is working)
* Ensuring background jobs are being processed (i.e. properties being imported, rates synced)
* Define custom alert required for the business (i.e. queue staleness alerts)

Cons:
* The logic that can be applied to a monitored action is pretty rudimentary. You can only set alerting rules on a single monitored action.
* Monitoring low volume actions (couple of events per day) makes it hard to define reactive alerts

### PagerDuty (PD)

PagerDuty is a tool that connects with external services like DD and NR. It’s main responsibility is ensuring the people who are on duty receive alerts.
It also allows us to view a report of past alerts and write notes on an individual alert.

## What to do when I get alerted?

* Don’t panic.
* Read the alert message and acknowledge the alert on PagerDuty. It’s important to acknowledge the alert so it doesn’t escalate and send email to every engineer in roots@housetrip.com group, or SMS messages to non duty-engineers.
* The alert message tells you about the symptom, your mission is to identify the cause. The message should point you in the right direction. i.e. “no enquiry email sent” should point towards the DJ not being processed.
* Fixing the issue. Don’t spend too much time on a perfect solution but find one that does the job and fixes the cause. Usually:
  * turn off a feature flag
  * temporary disable an AB test
  * deploy a hotfix
* Write a note on the PagerDuty alert. Be brief, don’t spend more time on documenting the alert than it took you fixing it. The note should include:
* What was the cause? Bonus points for including links to useful dashboards on NR or DD
* How did you fix the cause; useful for future duty comrades
* If the alert was not real or unactionable, remember to point that out. We need this info to continuously improve and maintain a good alert set. Again fellow engineers will appreciate it.

## Caveats

All this symptom based alerting is nice and brings the mindset closer to the end user’s, but what does one do when we have to deal with special situations like:

### Detecting very rare failures (< 1%)

Setting up the alert on symptoms would generate noise or ignore the cause. You don’t want to create noisy alerts!

### Symptom based alerting comes too late

An example here is how to deal with running out of quotas (free disk space, free Redis memory, …). Instead of alerting too late (less than a couple of hours until running out of storage), send a notification which raises the issue earlier (if we continue to grow at this rate, we will run out of quota in 1+ days) that can be resolved in office hours.

### Setting up the alerting around the symptom is too complicated

This goes hand in hand with the previous point. On a few rare occasions defining the symptom becomes overwhelming, hard to maintain and understand (i.e. read replica has become inaccessible). If it’s much simpler and accurate to alert on cause compared to the symptom, it’s worth making an exception to the rule.
