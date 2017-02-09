import React, { PropTypes, Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as userSettingsActions from '../../actions/userSettings'
import * as questionnaireActions from '../../actions/questionnaire'
// import * as routes from '../../routes'

class QuestionnaireOnboarding extends Component {
  static propTypes = {
    dispatch: PropTypes.func,
    questionnaire: PropTypes.object,
    userSettingsActions: PropTypes.object.isRequired,
    projectId: PropTypes.any,
    questionnaireActions: PropTypes.object.isRequired,
    router: PropTypes.object,
    onDismiss: PropTypes.func
  }

  componentDidMount() {
    $('.carousel.carousel-slider').carousel({
      full_width: true
    })
  }

  render() {
    const { onDismiss } = this.props
    return (
      <div className='col s12 m8 offset-m1'>
        <div className='carousel carousel-slider center' data-indicators='true'>
          <div className='carousel-fixed-item center'>
            <a onClick={() => onDismiss()}>Understood, create the first step</a>
          </div>
          <div className='carousel-item' href='#one!'>
            <div className='icons'>
              <i className='material-icons'>flag</i>
            </div>
            <h2>Multi-language questionnaires</h2>
            <p className=''>When you add more than one language a step for language selection will be enabled and you'll be able to define every step in each of the selected languages.</p>
          </div>
          <div className='carousel-item' href='#two!'>
            <div className='icons'>
              <i className='material-icons'>phone</i>
              <i className='material-icons'>chat</i>
            </div>
            <h2>Questionnaire modes</h2>
            <p className=''>When more than one mode is enabled you'll be able to set up messages and interactions at every step for each selected mode.</p>
          </div>
          <div className='carousel-item' href='#three!'>
            <div className='icons'>
              <i className='material-icons'>list</i>
              <i className='material-icons'>chat</i>
              <i className='material-icons'>call_split</i>
            </div>
            <h2>Questionnaire steps</h2>
            <p className=''>Questionnaires are organized in steps. Each step type offers different features like multiple choice, numeric input or just an explanation . The comparison steps allow A/B testing.</p>
          </div>
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    questionnaire: state.questionnaire.data,
    projectId: ownProps.params.projectId
  }
}

const mapDispatchToProps = (dispatch) => ({
  userSettingsActions: bindActionCreators(userSettingsActions, dispatch),
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireOnboarding))
