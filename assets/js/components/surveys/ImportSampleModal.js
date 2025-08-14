import React, { Component, PropTypes } from "react"
import { CardTable, Modal } from "../ui"
import { translate } from "react-i18next"
import values from "lodash/values"

class ImportSampleModal extends Component {
  static propTypes = {
    t: PropTypes.func,
    projectSurveys: PropTypes.object,
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
    const { projectSurveys, modalId, style, t } = this.props

    let surveys = values(projectSurveys || {}).filter((survey) => survey.state == "terminated")

    return (
      <div>
        <Modal card id={modalId} style={style}>
          <div className="modal-content">
            <div className="card-title header">
              <h5>{t("Import unused respondents")}</h5>
              <p>{t("You can import the respondents that haven't been contacted in finished surveys of the project")}</p>
            </div>
            <CardTable>
              <colgroup>
                <col width="70%" />
                <col width="30%" />
              </colgroup>
              <thead>
                <tr>
                  <th>{t("Name")}</th>
                  { /* <th>{t("Unused respondents")}</th> FIXME: should be this th instead of survey id */ }
                  <th>{t("Survey ID")}</th>
                </tr>
              </thead>
              <tbody>
                {surveys.map((survey) => {
                  let name = survey.name ? `${survey.name} (#${survey.id})` : <em>Untitled Survey #{survey.id}</em>
                  let unusedSampleCount = survey.id // FIXME: should be the respondents count
                  return <tr key={survey.id} onClick={() => this.onSubmit(survey.id)}>
                  <td>{name}</td>
                  <td>{unusedSampleCount}</td>
                </tr>})}
              </tbody>
            </CardTable>
          </div>
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
