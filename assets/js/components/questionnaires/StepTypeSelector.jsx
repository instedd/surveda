// @flow
import React, { Component } from "react"
import { bindActionCreators } from "redux"
import { connect } from "react-redux"
import { Dropdown, DropdownItem } from "../ui"
import { icon } from "../../step"
import * as questionnaireActions from "../../actions/questionnaire"
import { translate } from "react-i18next"

type Props = {
  stepType: string,
  readOnly: boolean,
  quotaCompletedSteps?: boolean,
  stepId: any,
  t: Function,
  questionnaireActions: any,
}

class StepTypeSelector extends Component<Props> {
  changeStepType(type) {
    this.props.questionnaireActions.changeStepType(this.props.stepId, type)
  }

  render() {
    const { stepType, readOnly, quotaCompletedSteps, t } = this.props

    const label = <i className="material-icons sharp">{icon(stepType)}</i>

    return (
      <div className="left">
        <Dropdown
          className="step-mode"
          readOnly={readOnly}
          label={label}
          constrainWidth={false}
          dataBelowOrigin={false}
        >
          <DropdownItem>
            <a onClick={(e) => this.changeStepType("multiple-choice")}>
              <i className="material-icons left">list</i>
              {t("Multiple choice")}
              {stepType == "multiple-choice" ? <i className="material-icons right">done</i> : ""}
            </a>
          </DropdownItem>
          <DropdownItem>
            <a onClick={(e) => this.changeStepType("numeric")}>
              <i className="material-icons left sharp">dialpad</i>
              {t("Numeric")}
              {stepType == "numeric" ? <i className="material-icons right">done</i> : ""}
            </a>
          </DropdownItem>
          <DropdownItem>
            <a onClick={(e) => this.changeStepType("explanation")}>
              <i className="material-icons left sharp">chat_bubble_outline</i>
              {t("Explanation")}
              {stepType == "explanation" ? <i className="material-icons right">done</i> : ""}
            </a>
          </DropdownItem>
          {quotaCompletedSteps ? null : (
            <DropdownItem>
              <a onClick={(e) => this.changeStepType("flag")}>
                <i className="material-icons left sharp">flag</i>
                {t("Flag")}
                {stepType == "flag" ? <i className="material-icons right">done</i> : ""}
              </a>
            </DropdownItem>
          )}
        </Dropdown>
      </div>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
})

export default translate()(connect(null, mapDispatchToProps)(StepTypeSelector))
