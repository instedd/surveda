import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as questionnaireActions from '../../actions/questionnaire'
import * as api from '../../api'
import * as routes from '../../routes'
import { icon } from '../../step'
import { Tooltip, ConfirmationModal, Card } from '../ui'

class SurveySimulation extends Component {
  constructor(props) {
    super(props)

    this.state = {
      state: 'pending',
      disposition: 'registered',
      stepId: null,
      stepIndex: null,
      responses: {},
      timer: null
    }
  }

  componentWillMount() {
    const { dispatch, projectId, surveyId } = this.props

    dispatch(actions.fetchSurveyIfNeeded(projectId, surveyId))
    .then(() => {
      const questionnaireId = this.props.survey.questionnaireIds[0]
      dispatch(questionnaireActions.fetchQuestionnaireIfNeeded(projectId, questionnaireId))
    })

    this.refresh()

    const timer = setInterval(() => { this.refresh() }, 5000)
    this.setState({timer})
  }

  componentWillUnmount() {
    if (this.state.timer) {
      clearInterval(this.state.timer)
    }
  }

  refresh() {
    const { projectId, surveyId } = this.props

    api.fetchSurveySimulationStatus(projectId, surveyId)
    .then(status => {
      this.setState({
        state: status.state,
        disposition: status.disposition,
        stepId: status.step_id,
        stepIndex: status.step_index,
        responses: status.responses
      })
    })
  }

  stopSimulation(e) {
    e.preventDefault()

    const { router, projectId, surveyId } = this.props

    const stopSimulationModal = this.refs.stopSimulationModal
    stopSimulationModal.open({
      modalText: <span>
        <p>Are you sure you want to stop the simulation</p>
      </span>,
      onConfirm: () => {
        api.stopSurveySimulation(projectId, surveyId)
        .then((response) => {
          router.replace(routes.questionnaire(projectId, response.questionnaire_id))
        })
      }
    })
  }

  stepsComponent() {
    const { questionnaire } = this.props

    if (!questionnaire) return null

    return (
      <Card>
        <ul className='collection simulation'>
          {questionnaire.steps.map((step, index) => this.stepComponent(step, index))}
        </ul>
      </Card>
    )
  }

  stepComponent(step, index) {
    let className = 'collection-item'
    let iconValue = icon(step.type)

    const value = this.state.responses[step.store]

    if (this.state.stepIndex && index < this.state.stepIndex) {
      if (value) {
        className += ' done'
        iconValue = 'check_circle'
      } else {
        className += ' skipped'
      }
    } else if (this.state.stepId == step.id) {
      className += ' active'
    }

    return (
      <li className={className} key={index}>
        <i className='material-icons left sharp'>{iconValue}</i>
        <span className='title'>{step.title}</span>
        <br />
        <span className='value'>{value}</span>
      </li>
    )
  }

  render() {
    return (
      <div>
        <Tooltip text='Stop simulation'>
          <a className='btn-floating btn-large waves-effect waves-light red right mtop' onClick={(e) => this.stopSimulation(e)}>
            <i className='material-icons'>clear</i>
          </a>
        </Tooltip>
        <ConfirmationModal modalId='survey_stop_simulation_modal' ref='stopSimulationModal' confirmationText='STOP' header='Stop simulation' showCancel />

        <div className='row'>
          <div className='col s4'>
            <p>
              Disposition: {this.state.disposition}
            </p>
          </div>
          <div className='col s8'>
            {this.stepsComponent()}
          </div>
        </div>
      </div>
    )
  }
}

SurveySimulation.propTypes = {
  dispatch: React.PropTypes.func,
  router: React.PropTypes.object,
  projectId: PropTypes.string,
  surveyId: PropTypes.string,
  survey: PropTypes.object,
  questionnaire: PropTypes.object
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    surveyId: ownProps.params.surveyId,
    survey: state.survey.data,
    questionnaire: state.questionnaire.data
  }
}

export default withRouter(connect(mapStateToProps)(SurveySimulation))
