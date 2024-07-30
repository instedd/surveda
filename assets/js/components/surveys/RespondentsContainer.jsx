import React, { PropTypes } from "react"
import { translate, Trans } from "react-i18next"

export const RespondentsContainer = translate()(({ children, t, incentivesEnabled }) => {
  const onClick = (e) => {
    e.preventDefault()
    window.open("/files/phone_numbers_example.csv")
  }
  const download = "phone_numbers_example.csv"

  return (
    <div>
      <div className="row">
        <div className="col s12">
          <h4>{t("Upload your respondents list")}</h4>
          <p className="flow-text">
            <Trans>
              Upload a CSV file like{" "}
              <a href="#" onClick={onClick} download={download}>
                this one
              </a>{" "}
              with your respondents. You can define how many of these respondents need to
              successfully answer the survey by setting up cutoff rules.
            </Trans>
            &nbsp;
            {t("Uploading a CSV with respondent ids disables incentive download.")}
            {incentivesEnabled ? null : (
              <div className="valign-wrapper upload-csv-warning">
                <i className="file-download-off-icon" />
                <p>{t("Incentive download was disabled because respondent ids were uploaded")}</p>
              </div>
            )}
          </p>
        </div>
      </div>
      <div className="row">
        <div className="col s12">{children}</div>
      </div>
    </div>
  )
})

RespondentsContainer.propTypes = {
  t: PropTypes.func,
  children: PropTypes.node,
  incentivesEnabled: PropTypes.bool,
}
