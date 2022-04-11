import React, { PropTypes, Component } from "react"
import { withRouter } from "react-router"
import { connect } from "react-redux"
import { translate } from "react-i18next"

class SurveyWizardPanelSurveyStep extends Component {
  static propTypes = {
    t: PropTypes.func,
    survey: PropTypes.object.isRequired,
    readOnly: PropTypes.bool.isRequired,
    dispatch: PropTypes.func.isRequired,
  }

  render() {
    const { t } = this.props

    return (
      <div>
        <div className="row">
          <div className="col s12">
            <h4>{t("Panel Survey")}</h4>
            <p className="flow-text">
              {t(
                "This is a wave of a panel survey. The settings from previous waves will be used as a template for this wave. Any changes made to this wave's settings will serve as a template for future waves of this panel survey"
              )}
            </p>
          </div>
        </div>
      </div>
    )
  }
}

export default translate()(withRouter(connect()(SurveyWizardPanelSurveyStep)))
