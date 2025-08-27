import React, { Component, PropTypes } from "react"
import { CardTable, Modal } from "../ui"
import { translate } from "react-i18next"
import { FormattedDate } from "react-intl"
import { Preloader } from "react-materialize"
import values from "lodash/values"

class ImportSampleModal extends Component {
  static propTypes = {
    t: PropTypes.func,
    unusedSample: PropTypes.array,
    onConfirm: PropTypes.func.isRequired,
    modalId: PropTypes.string.isRequired,
    style: PropTypes.object,
  }

  constructor(props) {
    super(props)
    this.state = {
      buckets: {},
      steps: {},
    }
  }

  onSubmit(selectedSurveyId) {
    let { onConfirm, modalId } = this.props
    $(`#${modalId}`).modal("close")
    onConfirm(selectedSurveyId)
  }

  render() {
    const { unusedSample, modalId, style, t } = this.props

    let surveys = values(unusedSample || {})

    let loadingDiv = <div className="import-sample-loading">
        <div className="preloader-wrapper active center">
          <Preloader />
        </div>
      </div>

    let surveysTable = <CardTable>
      <colgroup>
        <col width="70%" />
        <col width="30%" />
      </colgroup>
      <thead>
        <tr>
          <th>{t("Name")}</th>
          <th>{t("Unused respondents")}</th>
          <th>{t("Ended at")}</th>
        </tr>
      </thead>
      <tbody>
        {surveys.map((survey) => {
          let name = survey.name ? `${survey.name} (#${survey.survey_id})` : <em>Untitled Survey #{survey.survey_id}</em>
          return <tr key={survey.survey_id} onClick={() => this.onSubmit(survey.survey_id)}>
          <td>{name}</td>
          <td>{survey.respondents}</td>
          <td>
            <FormattedDate
              value={Date.parse(survey.ended_at)}
              day="numeric"
              month="short"
              year="numeric"
              />
          </td>
        </tr>})}
      </tbody>
    </CardTable>

    return (
      <div>
        <Modal card id={modalId} style={style}>
          <div className="modal-content">
            <div className="card-title header">
              <h5>{t("Import unused respondents")}</h5>
              <p>{t("You can import the respondents that haven't been contacted in finished surveys of the project")}</p>
            </div>
          </div>
          { unusedSample ? surveysTable : loadingDiv }
          <div className="card-action">
            <a href="#!" className="modal-action modal-close grey-text btn-link">
              {t("Cancel")}
            </a>
          </div>
        </Modal>
      </div>
    )
  }
}

export default translate()(ImportSampleModal)
