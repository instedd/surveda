import React, { Component } from "react"

import { bindActionCreators } from "redux"
import { connect } from "react-redux"
import { Tooltip, EditableTitleLabel } from "../ui"
import * as questionnaireActions from "../../actions/questionnaire"
import * as uiActions from "../../actions/ui"

import { translate } from "react-i18next"

type Props = {
  children: any,
  t: any,
  title: string,
  id: string,
  readOnly: boolean,
  questionnaireActions: any,
  uiActions: any,
  randomize: boolean,
}

class Section extends Component {
  props: Props

  toggleRandomize(sectionId, checked) {
    this.props.questionnaireActions.toggleRandomizeForSection(sectionId)
  }

  questionnaireAddStep(e, sectionId) {
    e.preventDefault()
    // Add the step then automatically expand it
    this.props.questionnaireActions.addStepToSectionWithCallback(sectionId).then((step) => {
      this.props.uiActions.selectStep(step.id, true)
    })
  }

  deleteSection(e, sectionId) {
    e.preventDefault()
    this.props.questionnaireActions.deleteSection(sectionId)
  }

  addStepComponent() {
    const { readOnly, id, t } = this.props

    return readOnly ? null : (
      <div className="row add-step">
        <div className="col s12">
          <a
            href="#!"
            className="btn-flat blue-text no-padd no-hover"
            onClick={(e) => this.questionnaireAddStep(e, id)}
          >
            {t("Add Step to Section")}
          </a>
        </div>
      </div>
    )
  }

  handleTitleSubmit(sectionId, value) {
    this.props.questionnaireActions.changeSectionTitle(sectionId, value)
  }

  render() {
    const { title, id, randomize, t, readOnly } = this.props
    return (
      <div className="section-container">
        <div className="section-container-header">
          <div className="switch">
            <label>
              <input
                type="checkbox"
                checked={randomize}
                onChange={() => this.toggleRandomize(id, randomize)}
                disabled={readOnly}
              />
              <span className="lever" />
              {t("Randomize")}
            </label>
          </div>
          <div className="section-number">
            <EditableTitleLabel
              title={title}
              entityName="section"
              onSubmit={(value) => {
                this.handleTitleSubmit(id, value)
              }}
              readOnly={readOnly}
              emptyText={t("Untitled section")}
              inputShort
            />
          </div>
          <Tooltip text={t("Delete section")}>
            <a href="#" className="close-section" onClick={(e) => this.deleteSection(e, id)}>
              <i className="material-icons">close</i>
            </a>
          </Tooltip>
        </div>
        {this.props.children}
        {this.addStepComponent()}
      </div>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  uiActions: bindActionCreators(uiActions, dispatch),
})

export default translate()(connect(null, mapDispatchToProps)(Section))
