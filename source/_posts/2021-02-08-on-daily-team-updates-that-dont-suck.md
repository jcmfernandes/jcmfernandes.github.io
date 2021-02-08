---
layout: post
title: on daily team updates that don't suck
---

**Daily team updates aren't status updates.** There, I said it. If that's not how you feel then something is wrong. Furthermore, daily team updates are a safety net, the last line of defense against under-communication. **Don't wait for your next daily team update to say something to the team or to someone**. Just go ahead and say it ASAP.

Jason Yip wrote an [amazing article](https://martinfowler.com/articles/itsNotJustStandingUp.html) on Martin Fowler's website about how to run efficient and effective daily update sessions. This article is heavily inspired by Jason's article. For all intents and purposes, daily team updates and daily standups are the same.

# What are daily team update sessions for?

Daily update sessions follow the [Anna Karenina Principle](https://en.wikipedia.org/wiki/Anna_Karenina_principle) as in all good ones are alike and all bad ones are unique. Interestingly, the medium on which these sessions are held highly influences their efficiency but not so much their effectiveness. While synchronous in-person or video sessions are, for example, prone to storytelling or problem solving that should be left for later, they aren't inherently less effective than their asynchronous written counterpart.

An effective daily update session must achieve the following goals (shamelessly copy&pasting directly from Jason's article because it's perfect):

- **Share understanding of goals.** Even if we thought we understood each other at the start (which we probably didn’t), our understanding drifts, as does the context within which we’re operating. A “team” where each team member is working toward different goals tends to be ineffective.
- **Coordinate efforts.** If the work doesn’t need to be coordinated, you don’t need a team. Conversely, if you have a team, I assume the work requires coordination. Poor coordination amongst team members tends to lead to poor outcomes.
- **Share problems and improvements.** One of the primary benefits of a team versus working alone is that team members can help each other when someone encounters a problem or discovers a better way of doing something. A “team” where team members are not comfortable sharing problems and/or do not help each other tends to be ineffective.
- **Identify as a team.** It is very difficult to psychologically identify with a group if you don’t regularly engage with the group. You will not develop a strong sense of relatedness even if you believe them to be capable and pursuing the same goals.

# What to say?

Answer the following questions:

1. **Any blockers or impediments? Is there anything you need help with?**
2. **What do you want to accomplish today and how do you plan to do it?**
3. **What did you accomplish yesterday?**

These are numbered for a reason. They are in descending order of importance to the team.

So what's the recipe here?

- **Focus on what changed.** Everyone trusts that you're working hard (well, if that's not the case then you have deep problems to solve) so it's not about showing that you did things but about what you accomplished. Link back what you did to what you're working on. You addressed the feedback on a PR and got it to be approved so a story is now waiting for QA review. You went to a meeting and agreed on the path forward for a story. It's OK if you didn't accomplish anything yesterday, we've all been there. Accomplishing doesn't mean finishing something. Agreeing and/or deciding on the name of a variable is an accomplishment.
- **Give context.** Don't assume everyone has all the JIRA issues in their mind. Saying "agreed on what library we are going to use for XPTO-222" will force many to have to go see what XPTO-222 is about. Picking up on this example, you could instead say "agreed on using the `cc-validator` library to validate credit card numbers (XPTO-222)". Much better, right?
- **State your needs.** If there's anything preventing you from changing the world, say it. Do you need your PR to be reviewed? Say it. Do you need admin access to a 3rd-party service? Say it. Do you need help because something broke on your computer? Say it.

So how does a good daily team update look like? An example:

1. **Any blockers or impediments? Is there anything you need help with?**
    1. I can't get a test to pass on PR #123 (JIRA XPTO-42). Alice is already helping me out but we haven't yet figured the problem. There's a thread on the team's channel and further assistance is appreciated!
    2. I need Bob to publish version 2050 of the event schemas so that I can consume, in `service-analytics`, the `very_important_data` we are now adding to `UpdateEvent`'s payload, as it's something we want to show on the event-log report (JIRA XPTO-2016).
    3. Waiting for Sofia's stakeholder review on JIRA XPTO-333.
2. **What do you want to accomplish today and how do you plan to do it?**
    1. Add bulk selection to the sessions page so that we can then send bulk-action requests to the API (JIRA XPTO-911). Feedback on the proposed API is welcome!
    2. Help Jane releasing the updated public API's documentation (JIRA XPTO-444) as I just read that she's going to be working on that and I wrote the current version.
3. **What did you accomplish yesterday?**
    1. Debugged and fixed an issue that was causing duplicated events to miss some ticket types. This was a hotfix and it's in production (JIRA XPTO-666).
    2. Agreed with Eve on the new design of our analytics dashboard (JIRA XPTO-321). Proposed the story for team estimation.
    3. Found out why some attendees were waiting so long in the networking area. Spoiler alert: it's due to a race condition. I left my findings in JIRA XPTO-999.

Another example:

1. **Any blockers or impediments? Is there anything you need help with?**
    1. I'm unable to get the presence system up and running, something I need sort out so I can start tackling JIRA XPTO-555. Both Alice and Bob tried to help me out but we still don't know what's happening. Help is appreciated, there's a thread on the team's channel.
    2. Waiting for the review on PR #777 (JIRA XPTO-2001). I assigned it to Sam but anyone is welcome to review it.
2. **What do you want to accomplish today and how do you plan to do it?**
    1. Add support for the away status to `service-presence` (JIRA XPTO-555). Anyone wanting to pair-program?
    2. Figure out and document why the pricing on the attendee reports is getting out wrong (JIRA XPTO-888).
3. **What did you accomplish yesterday?**
    1. Nothing. Read the blockers.

# Common Antipatterns

Circling back to the recipe we talked about before, please beware the following:

- Saying just "meetings".
- Saying just "code reviews" (saying "I got PR #234 approved" is very much OK).
- Saying just "bugs".
- Saying just "worked on XPTO-789".
- Saying just "continue to work on XPTO-789".
