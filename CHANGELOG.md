# InSTEDD Ask Changelog

## Hazel 0.8 (unreleased)

Deployment considerations:
* Configure multiple Verboice/Nuntium instances in staging to verify issue [#741](https://github.com/instedd/ask/issues/741)

### Tasks
* Internal survey broker refactored to accommodate for mobile web mode
* Log all unprocessable entities 422 errors to simplify troubleshooting [#735](https://github.com/instedd/ask/issues/735)

### Bugfixes
* Validate that audio files are actually uploaded in the questionnaire editor [#755](https://github.com/instedd/ask/issues/755)
* Ineligible respondents should not be marked as completed [#747](https://github.com/instedd/ask/issues/747)
* Sample CSV upload failed in Chrome in Windows [#691](https://github.com/instedd/ask/issues/691)
* Input texts in questionnaire are not reset if the user switches focus too fast [#717](https://github.com/instedd/ask/issues/717)
* Export files should use consistent naming for respondent id variable [#786](https://github.com/instedd/ask/issues/786)
* All questionnaire variables should be represented it the survey response file [#785](https://github.com/instedd/ask/issues/785)
* Ensure all retries are executed within the survey's schedule [#780](https://github.com/instedd/ask/issues/780)
* A survey cannot be started if its questionnaire is invalid [#763](https://github.com/instedd/ask/issues/763)
* Channels with a disconnected provider are now deleted as they were not working [#800](https://github.com/instedd/ask/issues/800)
* Minor style issues in questionnaire index for Reader users [#811](https://github.com/instedd/ask/issues/811)
* Handle non-numeric answers for language selection steps [#814](https://github.com/instedd/ask/issues/814)

### Features
* New lightweight responsive web application endpoint for mobile web mode respondents [#681](https://github.com/instedd/ask/issues/681), [#708](https://github.com/instedd/ask/issues/708)
* Validate and upload mobile web mode respondents answers [#709](https://github.com/instedd/ask/issues/709), [#711](https://github.com/instedd/ask/issues/711)
* Add mobile web mode to questionnaires [#675](https://github.com/instedd/ask/issues/675)
* Support multiple Verboice and Nuntium instances via server configuration [#741](https://github.com/instedd/ask/issues/741)
* Convert WAV files to MP3 on upload to reduce size [#777](https://github.com/instedd/ask/issues/777)
* Show up to two decimal positions in percentages in survey overview page [#754](https://github.com/instedd/ask/issues/754)
* Accept STOP keyword via SMS for stopping a survey for a respondent [#795](https://github.com/instedd/ask/issues/795)
* Show upload progress for CSV respondent files [#793](https://github.com/instedd/ask/issues/793)
* Force Twilio to cache uploaded audio resources [#807](https://github.com/instedd/ask/issues/807)
* Confirmation for stopping a survey [#805](https://github.com/instedd/ask/issues/805)


## Gingko 0.7.3

### Features
* Export full CSV log of respondent interactions via SMS and IVR (aka call record) [#701](https://github.com/instedd/ask/issues/701)

### Bugfixes
* Include mode in disposition history file [#662](https://github.com/instedd/ask/issues/662)
* Do not set disposition as complete if call is disconnected [#781](https://github.com/instedd/ask/issues/781)


## Gingko 0.7.2

### Bugfixes

* Support uploading questionnaire ZIP files up to 1GB (was 300mb) [#769](https://github.com/instedd/ask/issues/769)
* Refusing a numerical question using the # key on Voice mode was not working [#765](https://github.com/instedd/ask/issues/765)
* Do not store the refusal key as an answer for the question [#695](https://github.com/instedd/ask/issues/695)

### Features
* Support data for health initiative theme for the application, selectable from a new settings menu in each project [#750](https://github.com/instedd/ask/issues/750)
