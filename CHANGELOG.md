# InSTEDD Surveda Changelog

## 0.30.0

### Features

* Add panel surveys support - first cut. [#1815](https://github.com/instedd/surveda/pull/1815)
* Enable fast mobile web simulation i.e.: without a real device. [#1819](https://github.com/instedd/surveda/pull/1819)

### Bugfixes

* Updated multiple missing text translations

### Others

* Migrate build and CI to GitHub Actions. [#1812](https://github.com/instedd/surveda/pull/1812)
* Unify simulators look and feel. [#1817](https://github.com/instedd/surveda/pull/1817)

## 0.29.0

### Features

* Archive questionnaires. [#1778](https://github.com/instedd/surveda/pull/1778), [#1771](https://github.com/instedd/surveda/issues/1771)
* Enable mobile-web simulator to be used directly in browser. [#1787](https://github.com/instedd/surveda/pull/1787), [#1785](https://github.com/instedd/surveda/issues/1785)
* Add autocomplete to mobile-web question prompt. [#1782](https://github.com/instedd/surveda/pull/1782), [#1095](https://github.com/instedd/surveda/issues/1095)

### Bugfixes

* Show no surveys message when the project is empty. [#1783](https://github.com/instedd/surveda/pull/1783)
* Ensure attempts are at least every 10m. [#1781](https://github.com/instedd/surveda/pull/1781), [#570](https://github.com/instedd/surveda/issues/570)
* Enforce that simulated surveys APIs operate only with simulated surveys. [#1792](https://github.com/instedd/surveda/pull/1792)

## 0.28.0

### Features

* Allow filtering respondents using a search input. Check [wiki](https://github.com/instedd/surveda/wiki/How-to-filter-respondents) for valid expressions. [#1723](https://github.com/instedd/surveda/issues/1723), [#1735](https://github.com/instedd/surveda/pull/1735)
  * Clarify downloads and share link relation with this new filters. [#1746](https://github.com/instedd/surveda/issues/1746)
* Add column picker in respondents table. [#1745](https://github.com/instedd/surveda/pull/1745)
* Add partial relevant answered questions counter to respondents. [#1762](https://github.com/instedd/surveda/pull/1762)
* Allow sorting respondents by disposition. [#1756](https://github.com/instedd/surveda/pull/1756)
* Allow choosing page size in respondents and activities listings. [#1758](https://github.com/instedd/surveda/pull/1758), [#1774](https://github.com/instedd/surveda/pull/1774)
* Add survey's folder to navbar. [#1768](https://github.com/instedd/surveda/pull/1768)
* Add link to disposition flow chart wiki. [#1776](https://github.com/instedd/surveda/pull/1776)

### Bugfixes

* Support long questionnaire in SMS simulation. [#1750](https://github.com/instedd/surveda/pull/1750)
* Avoid wrongly rejecting respondents in completed dispositions. [#1754](https://github.com/instedd/surveda/pull/1754)

## 0.27.0

### Features

* New questionnaire simulator. [#1672](https://github.com/instedd/surveda/issues/1672), [#1696](https://github.com/instedd/surveda/pull/1696), [#1701](https://github.com/instedd/surveda/pull/1701), [#1705](https://github.com/instedd/surveda/pull/1705), [#1698](https://github.com/instedd/surveda/pull/1698), [#1718](https://github.com/instedd/surveda/pull/1718), [#1729](https://github.com/instedd/surveda/pull/1729)

### Bugfixes

* Include interim partials in cockpit metrics. [#1726](https://github.com/instedd/surveda/issues/1726), [1734](https://github.com/instedd/surveda/pull/1734)
* Handle partial relevant settings in exports and imports. [#1704](https://github.com/instedd/surveda/pull/1704)
* Fix questionnaire's audios export to work across instances. [#1711](https://github.com/instedd/surveda/pull/1711)
* Avoid showing onboarding when to fresh users when questionnaire is not empty or user is reader only. [#1727](https://github.com/instedd/surveda/pull/1727)
* Fix activity log entries when the user has no username, fallback to email. [#1720](https://github.com/instedd/surveda/pull/1720)
* Improve wording regarding cancelling/stopped entries in activity log. [#1719](https://github.com/instedd/surveda/pull/1719)
* Improve wording in skip logic. [#1706](https://github.com/instedd/surveda/pull/1706)
* Handle with expired Verboice calls when re-enqueueing from Surveda. [#1733](https://github.com/instedd/surveda/pull/1733)
* Fix metrics computing in Verboice callbacks. [#1731](https://github.com/instedd/surveda/pull/1731)

## 0.26.1

### Bugfixes

* Fix respondent start issue due to locks being acquired with different keys. [#1737](https://github.com/instedd/surveda/issues/1737), [#1738](https://github.com/instedd/surveda/issues/1738)

## 0.26.0

### Features

* Mark respondent as partial if the selected _partial relevant_ questions were answered. [#1689](https://github.com/instedd/surveda/issues/1689), [#1692](https://github.com/instedd/surveda/pull/1692), [#1693](https://github.com/instedd/surveda/pull/1693)
* Remove stalled respondent state since it's no longer needed due to [last retry time policy](https://github.com/instedd/surveda/issues/452). [#1684](https://github.com/instedd/surveda/pull/1684)

### Bugfixes

* Fix concurrency issue due to missing lock over respondents when cancelling survey. [#1683](https://github.com/instedd/surveda/pull/1683)
* Improve cutoff rules section when creating a survey. [#1666](https://github.com/instedd/surveda/issues/1666), [#1686](https://github.com/instedd/surveda/pull/1686)
* Add missing log entry when cancelling survey completes. [#1668](https://github.com/instedd/surveda/pull/1668)
* Avoid showing onboarding pages to readers of a projects. [#1107](https://github.com/instedd/surveda/issues/1107), [#1687](https://github.com/instedd/surveda/pull/1687)
* Removing a respondent no longer triggers a client-side error. [#1677](https://github.com/instedd/surveda/pull/1677), [1685](https://github.com/instedd/surveda/pull/1685)
* Improve styling. [#1679](https://github.com/instedd/surveda/pull/1679)
* Clarify expected screen resolutions for admin pages. [#1680](https://github.com/instedd/surveda/pull/1680)

## 0.25.0

### Features

* Handle respondent's `STOP` message by setting a final disposition and flagging it as `user_stopped`. [#1607](https://github.com/instedd/surveda/issues/1607)
* More accurate retries count for IVR calls. Enqueued calls does not show as an attempt until they are started. [#1589](https://github.com/instedd/surveda/issues/1589)
* Mobile surveys links can be visited multiple times. [#1521](https://github.com/instedd/surveda/issues/1521)
* Allow cloud Verboice and Nuntium to be used in local surveda development by adding a `base_callback_url` configuration. [#1624](https://github.com/instedd/surveda/issues/1624)

## 0.24.1

### Bugfixes

* Fix duplicate respondents while improving sanitation of phone numbers for on imports [#1639](https://github.com/instedd/surveda/issues/1639)
* Fix usage of deprecated timezones [#1653](https://github.com/instedd/surveda/issues/1653), [#1657](https://github.com/instedd/surveda/issues/1657)

## 0.24.0

### Features

* Use the last contact attempt wait time as the timeout to mark a respondent as stalled [#452](https://github.com/instedd/surveda/issues/452)
  * The default fallback delay is now 2 hours (previously 10 minutes). [0a732058](https://github.com/instedd/surveda/commit/0a73205850bb91e4192ebfc1c2bc282ea347e4a1)
* Add retries histogram to show scheduling of respondents [#1526](https://github.com/instedd/surveda/issues/1526)
* Improve wording and information shown of queue and cockpit [#1162](https://github.com/instedd/surveda/issues/1162), [#1636](https://github.com/instedd/surveda/issues/1636), [#1627](https://github.com/instedd/surveda/issues/1627)
* Improve wording in skip logic [#1557](https://github.com/instedd/surveda/issues/1557)
* Replace (deprecated) Google URL shortener service in favor of a configurable InSTEDD [shorter](https://github.com/instedd/shorter) instance [#1522](https://github.com/instedd/surveda/issues/1522)
* Add configurable email from address [#1549](https://github.com/instedd/surveda/issues/1549)
* Survey overview page shows start and end date [#1123](https://github.com/instedd/surveda/issues/1123)
* Add a description field to questionnaires [#1068](https://github.com/instedd/surveda/issues/1068)
* Survey is stopped by a background process [#1517](https://github.com/instedd/surveda/issues/1517)
* Curate list of languages for language autocomplete [#356](https://github.com/instedd/surveda/issues/356)
* Timezones are chosen with an autocomplete component [#297](https://github.com/instedd/surveda/issues/297)
  * Show the localtime of the selected timezone [#1604](https://github.com/instedd/surveda/issues/1604)
* Add date in incentive file [#1113](https://github.com/instedd/surveda/issues/1113)
* Improve order of responses CSV columns by included before the ones that are always present [#1136](https://github.com/instedd/surveda/issues/1136)
* Update mobile web url to `https://<server>/mobile/<respondent_id>?token=<token>` [#1520](https://github.com/instedd/surveda/issues/1520)
* Improve layout of numeric data in tables [#409](https://github.com/instedd/surveda/issues/409)
* Survey auto-save is now triggered without leaving the field [#280](https://github.com/instedd/surveda/issues/280)

### Bugfixes

* Fix cockpit progress calculations and labeling [#1600](https://github.com/instedd/surveda/issues/1600)
* Fix questionnaire export issues due to long audio files [#1525](https://github.com/instedd/surveda/issues/1525)
* Fix error in "Total call time" when expired calls are involved [#1452](https://github.com/instedd/surveda/issues/1452)
* Fix export of audio files when the questionnaire has sections [#1597](https://github.com/instedd/surveda/issues/1597)
* Fix styling in comparisons section [#644](https://github.com/instedd/surveda/issues/644)
* Some surveys couldn't be removed depending on its state [#1560](https://github.com/instedd/surveda/issues/1560)
* Do not log requeue of expired calls in the interactions file [#1519](https://github.com/instedd/surveda/issues/1519)
* Ignore answers on non-active modes to fix modes column in the respondents file [#1482](https://github.com/instedd/surveda/issues/1482)

## 0.23.2

### Bugfixes

* Calls' `not_after` limit spans for an extra day in western timezones [#1603](https://github.com/instedd/surveda/issues/1603)

## 0.23.1

### Features

* Show `total_call_time` as `23m 17s` [#1518](https://github.com/instedd/surveda/issues/1518)
* Keep the count of the number of retries used for SMS and IVR for each respondent [#1516](https://github.com/instedd/surveda/issues/1516)

## 0.23

### Features

* Survey folders [#1463](https://github.com/instedd/surveda/issues/1463)
* Prometheus metrics [#1472](https://github.com/instedd/surveda/issues/1472), [#1473](https://github.com/instedd/surveda/issues/1473)
* Prefix respondent IDs with `r` [#1497](https://github.com/instedd/surveda/issues/1497)
* Success rate and queue size cockpit [#1488](https://github.com/instedd/surveda/issues/1488)

### Bugfixes

* 'Quota completed steps' section cannot be disabled [#1490](https://github.com/instedd/surveda/issues/1490)
* Cannot change the sections order [#1496](https://github.com/instedd/surveda/issues/1496)
* Call duration is not computed on failed calls [#1502](https://github.com/instedd/surveda/issues/1502)

## Viburnum 0.22.1

### Features

* Add a column to the respondents CSV with the order of the sections [#1492](https://github.com/instedd/surveda/issues/1492)
* Enable remote shell for Elixir process [#1511](https://github.com/instedd/surveda/issues/1511)

### Bugfixes

* Dropdown does not open on first click [#1491](https://github.com/instedd/surveda/issues/1491)

## Viburnum 0.22

### Features

* Stricter selection of Nuntium channel [#1428](https://github.com/instedd/surveda/issues/1428)
* Alert to project admins when a channel is down [#1449](https://github.com/instedd/surveda/issues/1449)
* Include sample file name in respondents file [#1394](https://github.com/instedd/surveda/issues/1394)
* Remove whitespaces from respondents CSV column names [#1401](https://github.com/instedd/surveda/issues/1401)

### Bugfixes

* Activity log doesn't include entries regarding the questionnaire sections [#1419](https://github.com/instedd/surveda/issues/1419)
* Questionnaire CSV cannot be downloaded with Firefox [#1446](https://github.com/instedd/surveda/issues/1446)
* Some languages can't be found when uploading the translation CSV [#1423](https://github.com/instedd/surveda/issues/1423)
* When a quota is set to zero, cases are not rejected [#1470](https://github.com/instedd/surveda/issues/1470)
* Navigation alert when setting quotas [#1479](https://github.com/instedd/surveda/issues/1479)

## Ulmus 0.21.5

### Bugfixes

* Fix slow generation of disposition history file

## Ulmus 0.21.4

### Bugfixes

* Fix expired calls not being retried if the status callback was missed

## Ulmus 0.21.3

### Bugfixes

* Upgrade hackney library to fix issue with HTTP connections timing out (Guisso)

## Ulmus 0.21.2

### Bugfixes

* Fix slow generation of interactions file [#1455](https://github.com/instedd/surveda/issues/1455)
* Upgrade timezone library to fix issue with autoupdating of the TZ database

## Ulmus 0.21.1

### Bugfixes

* Survey results file does not include answers inside sections [#1454](https://github.com/instedd/surveda/issues/1454)
* Surveys with sections were failing if the last step's skip logic was `end_survey`.

## Ulmus 0.21

### Features

* Show progress when a questionnaire is being uploaded [#1444](https://github.com/instedd/ask/issues/1444)
* Integrate Intercom [#1440](https://github.com/instedd/ask/issues/1440)
* Show start time in survey overview [#1267](https://github.com/instedd/ask/issues/1267)

### Bugfixes

* Page was not scrolling when a step is added or expanded [#1441](https://github.com/instedd/ask/issues/1441)
* Autosave time dispalyed incorrectly [#1443](https://github.com/instedd/ask/issues/1443)
* Error when uploading new respondents to an ongoing survey [#1429](https://github.com/instedd/ask/issues/1429)

## Tanoak 0.20.1

### Bugfixes

* Timezone database was not updating automatically

## Tanoak 0.20

### Features

* Allow to lock surveys [#1438](https://github.com/instedd/ask/issues/1438)
* Survey descriptions [#1436](https://github.com/instedd/ask/issues/1436)

### Bugfixes

* Some dispositions were not being logged in the interactions file [#1413](https://github.com/instedd/ask/issues/1413)

## Spruce 0.19.1

### Bugfixes

* Timezone database was not updating automatically

## Spruce 0.19

### Features

* Add ID column in the interactions file [#1402](https://github.com/instedd/ask/issues/1402)
* Include interim partials in the dashboard [#1430](https://github.com/instedd/ask/issues/1430)

### Bugfixes

* Fix: target complete % is invalid when "interim partial" is involved [#1424](https://github.com/instedd/ask/issues/1424)
* Fix: quantity totals are invalid when quotas are used [#1425](https://github.com/instedd/ask/issues/1425)

## Redwood 0.18

### Features

* Embedded UI to create and edit Verboice and Nuntium channels [#1185](https://github.com/instedd/ask/issues/1185)

## Quercus 0.17

### Features

* Step sections with support for randomization of section order at runtime [#1398](https://github.com/instedd/ask/issues/1398), [#1399](https://github.com/instedd/ask/issues/1399)
* Phone number mapping per channel [#1397](https://github.com/instedd/ask/issues/1397)

## Pine 0.16.2

### Features

* Make all audio URLs end with .mp3 extension (fixes issue with Africa's Talking service) [#1426](https://github.com/instedd/ask/issues/1426)
* Allow SMS prompts with more than 160 chars [#1427](https://github.com/instedd/ask/issues/1427)

## Pine 0.16.1

### Bugfixes

* Fix error on channel page when the channel is shared with an archived project [#1396](https://github.com/instedd/ask/issues/1396)
* Allow longer text in `action_data` column for log entries [#1395](https://github.com/instedd/ask/issues/1395)

## Pine 0.16

### Features

* Localized UI (with translations in French and Spanish) [#1217](https://github.com/instedd/ask/issues/1217)
* Archive projects [#1216](https://github.com/instedd/ask/issues/1216)
* Autosave improvements [#1224](https://github.com/instedd/ask/issues/1224), [#1225](https://github.com/instedd/ask/issues/1225), [#1226](https://github.com/instedd/ask/issues/1226)
* New survey cockpit [#1218](https://github.com/instedd/ask/issues/1218)
* Record voice messages in the browser [#1223](https://github.com/instedd/ask/issues/1223)
* Activity log [#1227](https://github.com/instedd/ask/issues/1227)
* Undo/Redo in the questionnaire editor [#1253](https://github.com/instedd/ask/issues/1253)
* Share channels with projects [#1248](https://github.com/instedd/ask/issues/1248), [#1249](https://github.com/instedd/ask/issues/1249)

### Bugfixes

* Avoid deletion of respondent groups when the survey is already running [#1203](https://github.com/instedd/ask/issues/1203)
* Synchronize Verboice shared channels [#1219](https://github.com/instedd/ask/issues/1219)

## Oak 0.15.3

### Bugfixes

* Fix: Collaborator roles not appearing correctly [#1269](https://github.com/instedd/ask/issues/1269)

## Oak 0.15.2

### Bugfixes

* Fix error during launch of mobileweb surveys [#1273](https://github.com/instedd/ask/issues/1273)

## Oak 0.15.1

### Features

* Added "admin" role level with same permissions as "owner" [#1170](https://github.com/instedd/ask/issues/1170)

### Bugfixes

* Fix: invitations can be created for "owner" [#1263](https://github.com/instedd/ask/issues/1263)
* Fix: any value could be stored for membership level [#1262](https://github.com/instedd/ask/issues/1262)

## Oak 0.15

This release requires Verboice 3.2

### Features

* Support text responses for numeric questions [#1208](https://github.com/instedd/ask/issues/1208)
* Avoid calls out of the survey schedule [#1209](https://github.com/instedd/ask/issues/1209)

## Nutmeg 0.14.2

### Bugfixes

* Fix error when receiving delivery confirmation of messages from Nuntium when the mode is mobile web

## Nutmeg 0.14.1

### Bugfixes

* Fix regression of [#1156](https://github.com/instedd/ask/issues/1156)
* Fix issues with old surveys without channel stats stored [#1207](https://github.com/instedd/ask/issues/1207)

## Nutmeg 0.14

### Bugfixes

* Selecting "fallback mode" before "primary mode" raises an error [#1189](https://github.com/instedd/ask/issues/1189)
* [Questionnaire] On the simulator the mouse cursor is a `pointer` but nothing is clickable [#1190](https://github.com/instedd/ask/issues/1190)
* Changing the selected language doesn't change the loaded audio [#1194](https://github.com/instedd/ask/issues/1194)
* [Questionnaire] The 'Thank you message' is not mandatory but it's sent all the times [#1198](https://github.com/instedd/ask/issues/1198)

### Features

* Export stats in respondents CSV file [#1205](https://github.com/instedd/ask/issues/1205)
* Compute respondent stats [#1204](https://github.com/instedd/ask/issues/1204)
* Interim Partial [#1206](https://github.com/instedd/ask/issues/1206)
* Hide channel types when the provider is not configured [#1182](https://github.com/instedd/ask/issues/1182)
* Channel provider should display the full provider name [#1191](https://github.com/instedd/ask/issues/1191)
* All questions included in the quotas must be executed before rejecting the respondent. [#1156](https://github.com/instedd/ask/issues/1156)
* Avoid unintentional capture of phone numbers [#1180](https://github.com/instedd/ask/issues/1180)

## Maple 0.13.1

### Bugfixes

* Fix error when receiving delivery confirmation of messages from Nuntium when the mode is mobile web

## Maple 0.13

In this release the default batch size, applied to surveys with no cutoff rules, is raised to 10k. However this value can be customized on each deploy.

This version has some performance improvements to avoid runtime and UI errors when running with surveys with millions of respondents [#1154](https://github.com/instedd/ask/issues/1154), [#1186](https://github.com/instedd/ask/issues/1186)

### Features

* Added "last modified" column to questionnaires and allow sorting by this value [#1177](https://github.com/instedd/ask/issues/1177)
* Better warning message and UI before stopping a survey [#1157](https://github.com/instedd/ask/issues/1157)
* Shortlinks to access CSV downloads without authentication [#1184](https://github.com/instedd/ask/issues/1184)
* Block dates to skip survey scheduling [#1176](https://github.com/instedd/ask/issues/1176)

### Bugfixes

* Fix cases were respondents would be marked as "failed" when stopping responding after being in "completed" disposition [#1181](https://github.com/instedd/ask/issues/1181)
* Fix UI crash while selecting quotas [#1183](https://github.com/instedd/ask/issues/1183)
* Fix JS error in password reset form [#1124](https://github.com/instedd/ask/issues/1124)
* Error messages were not being displayed in mobile web [#1179](https://github.com/instedd/ask/issues/1179)
* Show time of the next execution of the survey in the timezone defined in the schedule [#1175](https://github.com/instedd/ask/issues/1175)
* Could not download CSV results for huge surveys [#1199](https://github.com/instedd/ask/issues/1199)
* Fix validation of refusal messages [#1120](https://github.com/instedd/ask/issues/1120)

## Larch 0.12.3

### Bugfixes

* Fix error when receiving delivery confirmation of messages from Nuntium when the mode is mobile web

## Larch 0.12.2

### Bugfixes

* Fixed issue with new Chrome versions [#1174](https://github.com/instedd/ask/issues/1174)

## Larch 0.12.1

Port fixes from 0.10.4

## Larch 0.12

There is a new endpoint to collect metrics by Prometheus. This endpoint can be protected with username and password using the environment variables METRICS_USER (defaults to "metrics") and METRICS_PASS.

In order to use Guisso for authentication and SSO, some new environment variables must be set:
  * GUISSO_ENABLED: boolean, defaults to `false`
  * GUISSO_BASE_URL: the base url of the Guisso server (ie: `https://login.instedd.org`)
  * GUISSO_CLIENT_ID and GUISSO_CLIENT_SECRET: credentials generated in Guisso for the Surveda application

### Features

* Integrated Prometheus endpoint to export HTTP metrics [#1115](https://github.com/instedd/ask/issues/1115)
* Single sign-on using Guisso [#1144](https://github.com/instedd/ask/issues/1144)
* OAuth2 authentication for APIs [#1145](https://github.com/instedd/ask/issues/1145)

## Katsura 0.11.2

### Bugfixes

* Fixed issue with new Chrome versions [#1174](https://github.com/instedd/ask/issues/1174)

## Katsura 0.11.1

Port fixes from 0.10.4

## Katsura 0.11

In this release the development platform was updated (Elixir 1.5, Phoenix 1.3, Ecto 2.1.6)

### Features

* Register in the interactions log whenever a respondent is enqueued in Verboice and also when a callback from Verboice was not received and the respondent timed out [#1127](https://github.com/instedd/ask/issues/1127)
* Results endpoint can filter by disposition, update timestamp and final state [#1143](https://github.com/instedd/ask/issues/1143)
* Results endpoint can return JSON [#1142](https://github.com/instedd/ask/issues/1142)

### Bugfixes

* Fixed inconsistent number of contacted respondents [#1128](https://github.com/instedd/ask/issues/1128)

## Juniper 0.10.4

### Bugfixes

* Fix respondent stats that were breaking sometimes when a respondent is in "completed" disposition but still active

## Juniper 0.10.3

### Features

* Customizable base url for the link sent to mobile web respondents (MOBILE_WEB_BASE_URL environment variable)

## Juniper 0.10.2

### Features

* The number of respondents enqueued by minute is now configurable with an environment variable (BROKER_BATCH_LIMIT_PER_MINUTE)

## Juniper 0.10.1

### Bugfixes

* Fix error when refusing a question [#1110](https://github.com/instedd/ask/issues/1110)
* Adjust position of tooltip over survey status [#1111](https://github.com/instedd/ask/issues/1111)
* Questionnaires were being set as invalid after importing [#1109](https://github.com/instedd/ask/issues/1109)

## Juniper 0.10

### Bugfixes

* Fix styling of validation messages on sign-in/sign-up forms [#899](https://github.com/instedd/ask/issues/899)
* Missing notification after uploading more respondents to a running survey [#1008](https://github.com/instedd/ask/issues/1008)
* Reloading issue when resetting the password [#737](https://github.com/instedd/ask/issues/737)
* Fix: If the range delimiters are invalid, the change is not saved [#727](https://github.com/instedd/ask/issues/727)
* Missing validation error when the ranges are invalid [#728](https://github.com/instedd/ask/issues/728)
* Styling issue with error messages in the questionnaire editor [#1014](https://github.com/instedd/ask/issues/1014)
* Do not crash when a channel was deleted [#791](https://github.com/instedd/ask/issues/791), [#549](https://github.com/instedd/ask/issues/549)
* Cannot select text within the questionnaire steps without dragging [#663](https://github.com/instedd/ask/issues/663)
* Missing texts (title, survey already taken, thank you) in the translation CSV files [#1021](https://github.com/instedd/ask/issues/1021), [#1038](https://github.com/instedd/ask/issues/1038)
* Faster CSV downloads to avoid timeouts [#1081](https://github.com/instedd/ask/issues/1081)
* Fixed: respondents were being marked as "breakoff" even when there are more retries available [#1031](https://github.com/instedd/ask/issues/1031)
* Survey would get stuck if the last step is used for quota definition [#1059](https://github.com/instedd/ask/issues/1059)
* Fix: readers cannot switch modes in the questionnaire editor [#1091](https://github.com/instedd/ask/issues/1091)
* Fix: runtime error when an experiment case was set with 0%  [#1094](https://github.com/instedd/ask/issues/1094)
* Step disappears while dragging [#1024](https://github.com/instedd/ask/issues/1024)
* Could not import respondents file with UTF-16 encoding [#1100](https://github.com/instedd/ask/issues/1100)
* Fix aspect ratio of Surveda logo in emails [#1082](https://github.com/instedd/ask/issues/1082)

### Features

* New design of survey overview page [#975](https://github.com/instedd/ask/issues/975), [#1001](https://github.com/instedd/ask/issues/1001)
* Shortcut buttons to apply style on mobile web prompts [#973](https://github.com/instedd/ask/issues/973)
* Repace "quota completed" message with customizable steps [#822](https://github.com/instedd/ask/issues/822)
* New design of questionnaire editor that displays one mode at a time [#992](https://github.com/instedd/ask/issues/992), [#996](https://github.com/instedd/ask/issues/996), [#1003](https://github.com/instedd/ask/issues/1003), [#1007](https://github.com/instedd/ask/issues/1007), [#998](https://github.com/instedd/ask/issues/998), [#1025](https://github.com/instedd/ask/issues/1025)
* Autocomplete for mobile web prompts [#997](https://github.com/instedd/ask/issues/997)
* Multiline prompts for IVR and SMS [#898](https://github.com/instedd/ask/issues/898)
* Display hint about surveys currently running but outside the schedule window [#1004](https://github.com/instedd/ask/issues/1004)
* Questionnaire preview [#999](https://github.com/instedd/ask/issues/999)
* Show validation error for duplicate variable names [#616](https://github.com/instedd/ask/issues/616)
* Link to questionnaires index [#773](https://github.com/instedd/ask/issues/773)
* Use questionnaire title for mobile web SMS [#903](https://github.com/instedd/ask/issues/903)
* Link the "about" to InSTEDD platform page [#267](https://github.com/instedd/ask/issues/267)
* Show language names in the responses CSV file [#787](https://github.com/instedd/ask/issues/787)
* Export timestamps in the timezone of the survey [#784](https://github.com/instedd/ask/issues/784)
* Include all used modes in the results CSV file [#572](https://github.com/instedd/ask/issues/572)
* Sort surveys by last update time (newest goes first) [#1015](https://github.com/instedd/ask/issues/1015)
* Performance improvements to import respondent files (allows bigger files to be loaded) [#704](https://github.com/instedd/ask/issues/704)
* Questionnaires can be deleted [#1018](https://github.com/instedd/ask/issues/1018)
* Sharing a project with an existing user doesn't send an invite anymore [#782](https://github.com/instedd/ask/issues/782)
* Pagination in the survey index [#990](https://github.com/instedd/ask/issues/990)
* Better error messages with error ID and details [#1019](https://github.com/instedd/ask/issues/1019)
* Collaborators can be removed or edited [#808](https://github.com/instedd/ask/issues/808)
* Store 'REFUSED' for refused questions as the answer instead of the key pressed by the respondent [#1077](https://github.com/instedd/ask/issues/1077)

## Ironwood 0.9.5

### Bugfixes

* Fix parsing of success rates environment variables so they can be expressed in %

## Ironwood 0.9.4

### Bugfixes

* Ignore channel callbacks for sessions already ended [#1023](https://github.com/instedd/ask/issues/1023)

## Ironwood 0.9.3

This release will convert all stored WAV audios to MP3 to improve the overall performance and reduce the time required to export a questionnaire ([#1029](https://github.com/instedd/ask/issues/1029))

### Bugfixes

* Fix error running surveys with questionnaire comparisons [#1030](https://github.com/instedd/ask/issues/1030)
* Cannot receive responses from some numeric questions [#1032](https://github.com/instedd/ask/issues/1032)
* Respondent marked as "started" with a timeout [#1028](https://github.com/instedd/ask/issues/1028)
* A breakoff when the disposition is already "partial" marks the respondent as failed [#1036](https://github.com/instedd/ask/issues/1036)
* Respondents CSV files contains duplicate or missing rows [#1037](https://github.com/instedd/ask/issues/1037), [#1046](https://github.com/instedd/ask/issues/1046)
* Fix issues with mode selection UI [#1033](https://github.com/instedd/ask/issues/1033)
* Failed respondents not being recorded in CSVs and Respondents tab [#1016](https://github.com/instedd/ask/issues/1016)
* Last "timeout" is not recorded in the respondent interactions [#1039](https://github.com/instedd/ask/issues/1039)
* Survey stops scheduling respondents when quotas are defined [#1041](https://github.com/instedd/ask/issues/1041)

## Ironwood 0.9.2

### Features

* Added more internal logging for survey scheduling (useful to diagnose issues with dynamic queue calculations)

## Ironwood 0.9.1

### Bugfixes

* Fix issue with dynamic queue size calculation

## Ironwood 0.9

Deployment considerations:
* A Google Api key is required to enable the URL shortening. Get one from https://console.developers.google.com/ and specify the value through GOOGLE_URL_SHORTENER_API_KEY environment variable.

### Bugfixes

* Show validation error when a multiple choice has less than two options [#883](https://github.com/instedd/ask/issues/883)
* Show validation error for missing prompt messages in language selection step [#882](https://github.com/instedd/ask/issues/882)
* Show error messages in mobile web form [#919](https://github.com/instedd/ask/issues/919)
* Fix skip logic for flag steps [#932](https://github.com/instedd/ask/issues/932)
* Respect timezone when scheduling new surveys [#938](https://github.com/instedd/ask/issues/938)
* Fix issue with min value of numeric questions not being saved [#726](https://github.com/instedd/ask/issues/726)
* Do not show received values for steps without variable names set [#950](https://github.com/instedd/ask/issues/950)
* Mobile web link to deleted survey was hanging on "loading" [#902](https://github.com/instedd/ask/issues/902)
* Fix last saved time sometimes displaying time in the future [#958](https://github.com/instedd/ask/issues/958)

### Features

* Properly handle mobile surveys opened many times (ie: on different tabs) [#870](https://github.com/instedd/ask/issues/870)
* Shorten URL links to mobile web form [#862](https://github.com/instedd/ask/issues/862)
* Show progress bar in mobile web form [#836](https://github.com/instedd/ask/issues/836)
* Ignore alphanumeric characters in responses for numeric steps [#867](https://github.com/instedd/ask/issues/867)
* Allow customization of "survey is over" message [#844](https://github.com/instedd/ask/issues/844)
* Allow customization of "thank you" message [#865](https://github.com/instedd/ask/issues/865)
* Disallow opening the link to mobile web form by different users [#863](https://github.com/instedd/ask/issues/863)
* New respondents can be added to a running survey [#845](https://github.com/instedd/ask/issues/845), [#926](https://github.com/instedd/ask/issues/926)
* Disable the submit button in mobile web form when the value is invalid [#931](https://github.com/instedd/ask/issues/931)
* Mark questionnaires with validation errors on the questionnaire list [#829](https://github.com/instedd/ask/issues/829)
* Added title setting for mobile web form [#837](https://github.com/instedd/ask/issues/837)
* Allow customization of "survey already taken" message [#866](https://github.com/instedd/ask/issues/866)
* Exported CSV files has the survey ID in the file names [#940](https://github.com/instedd/ask/issues/940)
* Re-design of questionnaire settings UI [#947](https://github.com/instedd/ask/issues/947)
* Run surveys over a 'snapshot' of the questionnaires [#913](https://github.com/instedd/ask/issues/913)
* Minimize time required to receive responses to multiple choice and numeric questions [#961](https://github.com/instedd/ask/issues/961)
* Allow sorting respondents table by hash or timestamp [#922](https://github.com/instedd/ask/issues/922)
* Show a "scroll indicator" for long mobile web forms [#917](https://github.com/instedd/ask/issues/917)
* Dynamically adjust the respondent queue size according to success rates [#939](https://github.com/instedd/ask/issues/939), [#957](https://github.com/instedd/ask/issues/957)
* Allow text formatting for mobile web forms [#710](https://github.com/instedd/ask/issues/710)
* Allow customization of mobile web form colors [#929](https://github.com/instedd/ask/issues/929)
* New disposition states [#946](https://github.com/instedd/ask/issues/946)

## Hazel 0.8.2

### Bugfixes

* Fix issues with refusal option in questionnaire editor [#918](https://github.com/instedd/ask/issues/918)

## Hazel 0.8.1

### Bugfixes

* Validation of file types is back when uploading respondents [#846](https://github.com/instedd/ask/issues/846)
* Ignore duplicate respondents that differs only in whitespace [#852](https://github.com/instedd/ask/issues/852)
* Could not continue after an explanation step in mobile web [#871](https://github.com/instedd/ask/issues/871)
* Non localized button in mobile web [#873](https://github.com/instedd/ask/issues/873)
* Various issues in language selection step for mobile web [#877](https://github.com/instedd/ask/issues/877), [#880](https://github.com/instedd/ask/issues/880), [#892](https://github.com/instedd/ask/issues/892)
* Value entered in numeric step persists in the next numeric question [#888](https://github.com/instedd/ask/issues/888)
* Interactions CSV shows "SMS" when the mobile web mode is used [#875](https://github.com/instedd/ask/issues/875)
* Show the right mode when mobile web is used [#879](https://github.com/instedd/ask/issues/879)
* Fix styling issues with retries UI for mobile web [#886](https://github.com/instedd/ask/issues/886)
* Remove "next" button when the "survey is over" message is displayed [#893](https://github.com/instedd/ask/issues/893)
* Display validation errors for mobile web in the questionnaire editor [#876](https://github.com/instedd/ask/issues/876), [#896](https://github.com/instedd/ask/issues/896)
* Issues with flag steps in mobile web [#900](https://github.com/instedd/ask/issues/900)
* Fix font size for mobile web [#885](https://github.com/instedd/ask/issues/885)
* Fix import/export of questionnaires with mobile web mode enabled [#909](https://github.com/instedd/ask/issues/909)
* Allow long messages to be stored for mobile web [#897](https://github.com/instedd/ask/issues/897)
* Include prompts for mobile web fields in the translation CSV [#910](https://github.com/instedd/ask/issues/910)

## Hazel 0.8

Deployment considerations:
* Configure multiple Verboice/Nuntium instances in staging to verify issue [#741](https://github.com/instedd/ask/issues/741)
* SSL is now mandatory in production mode

### Tasks
* Internal survey broker refactored to accommodate for mobile web mode [#676](https://github.com/instedd/ask/issues/676)
* Log all unprocessable entities 422 errors to simplify troubleshooting [#735](https://github.com/instedd/ask/issues/735)
* Enforce SSL (fixes [#530](https://github.com/instedd/ask/issues/530))
* Renamed the application to Surveda [#783](https://github.com/instedd/ask/issues/783)

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
* Disable scrolling in Download CSV popup and enlarge it so that all options are visible [#788](https://github.com/instedd/ask/issues/788)
* Wrong fallback mode displayed in the survey page [#752](https://github.com/instedd/ask/issues/752)
* Disable total cutoff if group quotas are set and vice versa [#759](https://github.com/instedd/ask/issues/759)
* Error when exporting huge questionnaires [#768](https://github.com/instedd/ask/issues/768)
* Style issues for tooltips [#797](https://github.com/instedd/ask/issues/797)
* Mark stalled respondents as failed after 8 hours [#812](https://github.com/instedd/ask/issues/812)
* Style issue with survey charts [#820](https://github.com/instedd/ask/issues/820)
* Record STOP actions in interactions CSV [#832](https://github.com/instedd/ask/issues/832)

### Features
* New lightweight responsive web application endpoint for mobile web mode respondents [#681](https://github.com/instedd/ask/issues/681), [#708](https://github.com/instedd/ask/issues/708), [#682](https://github.com/instedd/ask/issues/682), [#683](https://github.com/instedd/ask/issues/683), [#684](https://github.com/instedd/ask/issues/684), [#677](https://github.com/instedd/ask/issues/677), [#678](https://github.com/instedd/ask/issues/678), [#679](https://github.com/instedd/ask/issues/679), [#680](https://github.com/instedd/ask/issues/680), [#721](https://github.com/instedd/ask/issues/721), [#723](https://github.com/instedd/ask/issues/723)
* Validate and upload mobile web mode respondents answers [#709](https://github.com/instedd/ask/issues/709), [#711](https://github.com/instedd/ask/issues/711)
* Add mobile web mode to questionnaires [#675](https://github.com/instedd/ask/issues/675)
* Support multiple Verboice and Nuntium instances via server configuration [#741](https://github.com/instedd/ask/issues/741)
* Convert WAV files to MP3 on upload to reduce size [#777](https://github.com/instedd/ask/issues/777)
* Show up to two decimal positions in percentages in survey overview page [#754](https://github.com/instedd/ask/issues/754)
* Accept STOP keyword via SMS for stopping a survey for a respondent [#795](https://github.com/instedd/ask/issues/795)
* Show upload progress for CSV respondent files [#793](https://github.com/instedd/ask/issues/793)
* Force Twilio to cache uploaded audio resources [#807](https://github.com/instedd/ask/issues/807)
* Confirmation for stopping a survey [#805](https://github.com/instedd/ask/issues/805)
* Export MNO error codes in respondent interaction log  [#821](https://github.com/instedd/ask/issues/821)
* Show upload progress for audio files [#792](https://github.com/instedd/ask/issues/792)
* Show upload progress for questionnaire files [#794](https://github.com/instedd/ask/issues/794)
* Added "refused" flag as a disposition option [#828](https://github.com/instedd/ask/issues/828)
* Do not switch to fallback mode if calls are still enqueued in Verboice [#830](https://github.com/instedd/ask/issues/830)


## Gingko 0.7.3

### Features
* Export full CSV log of respondent interactions via SMS and IVR (aka call record) [#701](https://github.com/instedd/ask/issues/701), [#779](https://github.com/instedd/ask/issues/779)

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
