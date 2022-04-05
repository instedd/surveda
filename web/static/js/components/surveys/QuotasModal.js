import React, { Component, PropTypes } from "react"
import { stepStoreValues } from "../../reducers/questionnaire"
import { rebuildInputFromQuotaBuckets } from "../../reducers/survey"
import { Modal } from "../ui"
import filter from "lodash/filter"
import map from "lodash/map"
import join from "lodash/join"
import includes from "lodash/includes"
import { translate } from "react-i18next"

class QuotasModal extends Component {
  static propTypes = {
    t: PropTypes.func,
    showLink: PropTypes.bool,
    linkText: PropTypes.string,
    header: PropTypes.string.isRequired,
    survey: PropTypes.object.isRequired,
    questionnaire: PropTypes.object.isRequired,
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

  onSubmit(e) {
    e.preventDefault()
    const selectedVars = map(
      filter(Object.keys(this.state.buckets), (value) => this.state.buckets[value].checked),
      (quotaVar) => ({
        var: quotaVar,
        steps: (this.state.steps[quotaVar] || "").value,
      })
    )
    this.props.onConfirm(selectedVars)
  }

  render() {
    const { showLink, linkText, header, survey, questionnaire, modalId, style, t } = this.props

    this.state.buckets = {}

    let modalLink = null
    if (showLink) {
      modalLink = (
        <a className="modal-trigger edit-quotas" href={`#${modalId}`}>
          {linkText}
        </a>
      )
    }
    const storeValues = stepStoreValues(questionnaire)

    return (
      <div>
        {modalLink}
        <Modal card id={modalId} style={style}>
          <div className="modal-content">
            <div className="card-title header">
              <h5>{header}</h5>
              <p>{t("Choose the questionnaire answers you want to use to define quotas")}</p>
            </div>
            <div className="card-content">
              {Object.keys(storeValues).map((storeValue) => {
                let type = storeValues[storeValue].type
                if (type != "numeric" && type != "multiple-choice") {
                  return null
                } else {
                  return (
                    <div className="row" key={storeValue}>
                      <div className="col s12">
                        {type == "numeric" ? (
                          <div className="question left">
                            <div className="question-icon-label">
                              <i className="material-icons v-middle left">dialpad</i>
                              <span>{storeValue}</span>
                            </div>
                            <div className="question-value">
                              <div className="input-field">
                                <input
                                  type="text"
                                  ref={(node) => {
                                    this.state.steps[storeValue] = node
                                  }}
                                  defaultValue={rebuildInputFromQuotaBuckets(storeValue, survey)}
                                />
                                <span className="small-text-bellow">
                                  {t("Enter comma-separated values to create ranges like 5,10,20")}
                                </span>
                              </div>
                            </div>
                          </div>
                        ) : (
                          <div className="question left">
                            <div className="question-icon-label">
                              <i className="material-icons v-middle left">list</i>
                              <span>{storeValue}</span>
                            </div>
                            <div className="question-value">
                              {join(storeValues[storeValue].values, ", ")}
                            </div>
                          </div>
                        )}
                        <div className="question right">
                          <input
                            type="checkbox"
                            className="filled-in"
                            id={storeValue}
                            defaultChecked={includes(survey.quotas.vars, storeValue)}
                            ref={(node) => {
                              this.state.buckets[storeValue] = node
                            }}
                          />
                          <label htmlFor={storeValue} />
                        </div>
                      </div>
                    </div>
                  )
                }
              })}
            </div>
          </div>
          <div className="card-action">
            <a
              href="#!"
              className="modal-action modal-close waves-effect waves-light blue btn-large"
              onClick={(e) => this.onSubmit(e)}
            >
              {t("Done")}
            </a>
            <a href="#!" className="modal-action modal-close grey-text btn-link">
              {t("Cancel")}
            </a>
          </div>
        </Modal>
      </div>
    )
  }
}

export default translate()(QuotasModal)
