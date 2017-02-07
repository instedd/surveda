import React, { PropTypes, Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as userSettingsActions from '../../actions/userSettings'
import * as questionnaireActions from '../../actions/questionnaire'

class QuestionnaireOnboarding extends Component {
  static propTypes = {
    dispatch: PropTypes.func,
    questionnaire: PropTypes.object,
    userSettingsActions: PropTypes.object.isRequired,
    questionnaireActions: PropTypes.object.isRequired
  }

  hideOnboarding(e) {
    const { userSettingsActions } = this.props
    Promise.resolve(userSettingsActions.hideOnboarding()).then(
      () => {
        this.props.userSettingsActions.fetchSettings()
        this.props.questionnaireActions.addStep()
      })
  }

  render() {
    return (
      <div>
        <div>
          <h2>Multi-language questionnaires</h2>
          <div>
            When you add more than one language a step for language selection will be enabled and you'll be able to define every step in each of the selected languages.
          </div>
        </div>
        <div>
          <h2>Questionnaire modes</h2>
          <div>
            When more than one mode is enabled you'll be able to set up messages and interactions at every step for each selected mode.
          </div>
        </div>
        <div>
          <h2>Questionnaire steps</h2>
          <div>
            Questionnaires are organized in steps. Each step type offers different features like multiple choice, numeric input or just an explanation. The comparison steps allows A/B testing.
          </div>
        </div>
        <div>
          <a onClick={e => this.hideOnboarding(e)}>Understood, create the first step</a>
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    questionnaire: state.questionnaire.data
  }
}

const mapDispatchToProps = (dispatch) => ({
  userSettingsActions: bindActionCreators(userSettingsActions, dispatch),
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireOnboarding))
