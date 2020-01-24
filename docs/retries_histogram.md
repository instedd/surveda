# Retries Histogram

## Write
### Places where RetryStats are modified
 * `Broker.start` -> `handle_session_started`: All respondents are started from here. 
 This is the only place where respondents are **added** to the histogram.
 
 * `Broker.sync_step` -> `handle_next_action`: All respondent interactions go through here. 
 Depending on broker response (whether is a `:reply` or an `:end`) and `mode`, 
 respondent is **reallocated** in the histogram or **removed** from it.
 This is the happy-way of removing a respondent from the histogram, because the respondent completed the survey.
 
 * `Session.retry`: where respondents are effectively retried (contacted, it's retries decreased and attempts increased)
 Always, in this case, the respondent is **reallocated** in the histogram.
 
 * `Session.switch_to_fallback_mode`: when a respondent fallbacks to another `mode`.
 This always means the respondent is **reallocated** in the histogram.
 
 * `VerboiceChannel.callback(path=status)`: when verboice status is `failed`, `busy`, or `no-answer`, the call could not 
  get through or was interrupted. 
  This means the respondent is no longer active, so it must be **reallocated** from 
  an `ivr-active` slot to a `non-ivr-active` one.
 
 * `Session.timeout [no retries left]`: Session is terminated, so respondent is **removed** from the histogram 
 
 * `Broker.channel_failed [no retries left & no fallback mode left]`: Respondent is marked as `failed` 
 so is **removed** from the histogram.
 
 * `Broker.mark_stalled_for_eight_hours_respondents_as_failed`: the respondent ended the survey without responding, 
 so is **removed** from the histogram. 
 

### Considerations

* **ivr**: when call expires (verboice couldn't call the respondent in the given time-window), surveda considers the respondent is still active. 
Respondent is re-contacted, **but kept in the same histogram-slot.**

* **sms**: when a respondent replies a message its timeout is reset and the attempt is not increased
 
* **stalled-respondents**: in the current version stalled-respondents are removed from the histogram. 
If a stalled respondent replies a message before being marked as `failed` it will not appear in the histogram
(this is a side-effect of not considering this case in `session.timeout` -> `terminate`).

## Read

* **sms**: the respondent is considered `active` (active-attempt histogram column) 
if its `retry_stat.retry_stat_time` is in _n_ hours being _n_ the delay between attempts

* **sms**: when a respondent replies a message goes back to the current-attempt active slot
 
* **ivr**: the `non-ivr-active` respondents that have _n_ hours to the next attempt (being _n_ the delay between attempts) 
are shown in the ivr-active slot until the hour expires