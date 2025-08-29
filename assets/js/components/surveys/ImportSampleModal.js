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

  onSubmit(event, selectedSurveyId) {
    event.preventDefault()
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
        <col width="40%" />
        <col width="20%" />
        <col width="30%" />
        <col width="10%" />
      </colgroup>
      <thead>
        <tr>
          <th>{t("Name")}</th>
          <th>{t("Unused respondents")}</th>
          <th>{t("Ended at")}</th>
          <th />
        </tr>
      </thead>
      <tbody>
        {surveys.map((survey) => {
          let name = survey.name ? `${survey.name} (#${survey.survey_id})` : <em>Untitled Survey #{survey.survey_id}</em>
          const canBeImported = survey.respondents > 0
          const importButton = canBeImported ? 
            (<a href="#" onClick={(e) => this.onSubmit(e, survey.survey_id)} className="blue-text btn-flat">
              {t("Import")}
            </a>) : (<a href="#" onClick={(e) => e.preventDefault()} className="btn-flat disabled">
              {t("Import")}
            </a>)
          return <tr key={survey.survey_id}>
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
          <td>{importButton}</td>
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
