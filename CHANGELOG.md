# InSTEDD Ask Changelog

## Hazel 0.8 (unreleased)

Deployment considerations:
* Configure multiple Verboice/Nuntium instances in staging to verify issue #741

### Tasks
* Internal survey broker refactored to accommodate for mobile web mode
* Log all unprocessable entities 422 errors to simplify troubleshooting #735

### Bugfixes
* Validate that audio files are actually uploaded in the questionnaire editor #755
* Ineligible respondents should not be marked as completed #747
* Sample CSV upload failed in Chrome in Windows #691
* Input texts in questionnaire are not reset if the user switches focus too fast #717
* Export files should use consistent naming for respondent id variable #786
* All questionnaire variables should be represented it the survey response file #785
* Ensure all retries are executed within the survey's schedule #780
* A survey cannot be started if its questionnaire is invalid #763
* Channels with a disconnected provider are now deleted as they were not working #800
* Minor style issues in questionnaire index for Reader users #811
* Handle non-numeric answers for language selection steps #814

### Features
* New lightweight responsive web application endpoint for mobile web mode respondents #681, #708
* Validate and upload mobile web mode respondents answers #709, #711
* Add mobile web mode to questionnaires #675
* Support multiple Verboice and Nuntium instances via server configuration #741
* Convert WAV files to MP3 on upload to reduce size #777
* Show up to two decimal positions in percentages in survey overview page #754
* Accept STOP keyword via SMS for stopping a survey for a respondent #795
* Show upload progress for CSV respondent files #793
* Force Twilio to cache uploaded audio resources #807
* Confirmation for stopping a survey #805


## Gingko 0.7.3

### Features
* Export full CSV log of respondent interactions via SMS and IVR (aka call record) #701

### Bugfixes
* Include mode in disposition history file #662
* Do not set disposition as complete if call is disconnected #781


## Gingko 0.7.2

### Bugfixes

* Support uploading questionnaire ZIP files up to 1GB (was 300mb) #769
* Refusing a numerical question using the # key on Voice mode was not working #765
* Do not store the refusal key as an answer for the question #695

### Features
* Support data for health initiative theme for the application, selectable from a new settings menu in each project #750
