import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../../actions/survey'
import * as questionnaireActions from '../../actions/questionnaire'
import { hasSections } from '../../reducers/questionnaire'
import * as api from '../../api'
import * as routes from '../../routes'
import { icon } from '../../step'
import { Tooltip, ConfirmationModal, Card, UntitledIfEmpty } from '../ui'
import { translate } from 'react-i18next'
import flatten from 'lodash/flatten'
import DispositionChart from '../simulation/DispositionChart'
import ChatWindow from '../simulation/ChatWindow'

class SurveySimulation extends Component {
  constructor(props) {
    super(props)

    this.state = {
      state: 'pending',
      disposition: 'registered',
      sectionHistory: [],
      stepId: null,
      sectionIndex: null,
      stepIndex: null,
      responses: {},
      timer: null,
      errorCount: 0,
      initialState: null,
      mobileWebUrl: null
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
    this.loadInitialStateIfNeeded()
    this.refreshStatus()
  }

  initialStateLoaded() {
    return !!this.state.initialState
  }

  respondentIsActive() {
    return this.state.state == 'active'
  }

  respondentIsReady() {
    return this.respondentIsActive() && this.initialStateLoaded()
  }

  loadInitialStateIfNeeded() {
    const respondentIsActive = this.respondentIsActive()
    if (this.initialStateLoaded() || !respondentIsActive) return
    const { projectId, surveyId, mode } = this.props
    api.fetchSurveySimulationInitialState(projectId, surveyId, mode)
    .then(initialState => {
      this.setState({initialState})
    })
  }

  refreshStatus() {
    const { projectId, surveyId, questionnaire } = this.props

    api.fetchSurveySimulationStatus(projectId, surveyId)
    .then(status => {
      let sectionHistory = this.state.sectionHistory
      let sectionIndex = null
      let stepIndex = status.step_index

      if (questionnaire && status.step_index && hasSections(questionnaire.steps)) {
        sectionIndex = status.step_index[0]
        stepIndex = status.step_index[1]
        if (!sectionHistory.includes(sectionIndex)) {
          sectionHistory = [...sectionHistory, sectionIndex]
        }
      }

      this.setState({
        state: status.state,
        disposition: status.disposition,
        sectionHistory: sectionHistory,
        stepId: status.step_id,
        stepIndex: stepIndex,
        sectionIndex: sectionIndex,
        responses: status.responses,
        errorCount: 0
      })
    }, error => {
      if (this.state.errorCount >= 2) {
        // Three errors occurred in a row. Raise the error here.
        return Promise.reject(error)
      } else {
        this.setState(prevState => ({errorCount: prevState.errorCount + 1}))
      }
    })
  }

  stopSimulation(e) {
    e.preventDefault()

    const { router, projectId, surveyId, t } = this.props

    const stopSimulationModal = this.refs.stopSimulationModal
    stopSimulationModal.open({
      modalText: <span>
        <p>{t('Are you sure you want to stop the simulation')}</p>
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
    let stepList = null
    if (hasSections(questionnaire.steps)) {
      stepList = flatten(questionnaire.steps.map((step, index) => this.stepsComponentWhenSections(step, index)))
    } else {
      stepList = questionnaire.steps.map((step, index) => this.stepComponent(step, index))
    }

    return (
      <Card>
        <ul className='collection simulation'>
          {stepList}
        </ul>
      </Card>
    )
  }

  stepsComponentWhenSections(step, index) {
    const sectionHistory = this.state.sectionHistory
    const sectionIndex = this.state.sectionIndex
    const stepIndex = this.state.stepIndex
    const stepList = []
    let className = 'collection-item'
    let iconValue = icon(step.type)
    if (step.type === 'language-selection') {
      if (index == sectionIndex) {
        className = className + ' active'
      } else if (this.state.disposition === 'completed' || index < sectionIndex) {
        className += ' done'
        iconValue = 'check_circle'
      }
      stepList.push(this.stepItem(step, this.state.responses[step.store], 0, className, iconValue))
    } else if (step.type === 'section') {
      // add the section step to the stepList
      stepList.push(this.stepItem(step, null, index, className, iconValue))
      let value = null
      for (let i = 0; i < step.steps.length; i++) {
        const stepInSection = step.steps[i]
        value = this.state.responses[stepInSection.store]
        className = 'collection-item'
        iconValue = icon(stepInSection.type)
        if (sectionHistory.includes(index)) {
          if (index !== sectionIndex || this.state.disposition === 'completed') {
            // scope: inside a section that has already been executed
            [className, iconValue] = this.computeClassNameAndIcon(value, className, iconValue)
          } else if (index == sectionIndex) {
            // scope: inside the section that is been executed at this moment
            if (i < stepIndex) {
              [className, iconValue] = this.computeClassNameAndIcon(value, className, iconValue)
            } else if (i == stepIndex) {
              className += ' active'
            }
          }
        }
        // add each of the steps inside the section to the steplist
        stepList.push(this.stepItem(stepInSection, value, `${index}${i}`, className, iconValue))
      }
    }
    return stepList
  }

  computeClassNameAndIcon(value, className, iconValue) {
    let newClassName = null
    let newIconValue = null
    if (value) {
      newClassName = className + ' done'
      newIconValue = 'check_circle'
    } else {
      newClassName = className + ' skipped'
      newIconValue = iconValue
    }
    return [newClassName, newIconValue]
  }

  stepComponent(step, index) {
    let className = 'collection-item'
    let iconValue = icon(step.type)
    const stepIndex = this.state.stepIndex

    const value = this.state.responses[step.store]

    if ((stepIndex && index < stepIndex) || this.state.disposition === 'completed') {
      [className, iconValue] = this.computeClassNameAndIcon(value, className, iconValue)
    } else if (this.state.stepId == step.id) {
      className += ' active'
    }

    return this.stepItem(step, value, index, className, iconValue)
  }

  stepItem(step, value, key, className, iconValue) {
    const { t } = this.props
    const emptyText = step.type === 'section' ? t('Untitled section') : t('Untitled question')
    return (
      <li className={className} key={key}>
        <i className='material-icons left sharp'>{iconValue}</i>
        <UntitledIfEmpty className='title' text={step.title} emptyText={emptyText} />
        <br />
        <span className='value'>{value}</span>
      </li>
    )
  }

  mobileWebChatMessages() {
    const { mode, t } = this.props
    const { state, initialState } = this.state
    if (mode != 'mobileweb') return []
    const respondentIsActive = this.respondentIsActive()
    const respondentIsPendingOrActive = state == 'pending' || respondentIsActive
    const initialStateLoaded = this.initialStateLoaded()

    let messages = []
    if (respondentIsPendingOrActive && !initialStateLoaded) {
      messages = [t('Waiting for messages to be sent. This could take up to 1 minute.')]
    } else if (!respondentIsActive) {
      messages = [t('This simulation has ended')]
    } else if (initialStateLoaded) {
      messages = initialState.mobile_contact_messages
    }

    return messages.map(msg => ({
      type: 'ao',
      body: msg
    }))
  }

  onChatWindowClick(event) {
    const { className, href } = event.target
    if (className == 'linkified') {
      event.preventDefault()
      this.setState({mobileWebUrl: href})
    }
  }

  mobileWebSimulation() {
    const { t } = this.props
    const { disposition, mobileWebUrl } = this.state
    return (
      <div className='quex-simulation-container'>
        <DispositionChart disposition={disposition} />
        <div>
          {this.stepsComponent()}
        </div>
        {
          mobileWebUrl
          ? <div className='mobile-web-iframe-container'>
            <div className='chat-header'>
              <button onClick={() => { this.setState({mobileWebUrl: null}) }}>
                <i className='material-icons white-text'>arrow_back</i>
              </button>
              <div className='title'>
                {t('Mobileweb mode')}
              </div>
            </div>
            <iframe src={mobileWebUrl} className={'mobile-web'} />
          </div>
          : <div onClick={event => this.onChatWindowClick(event)}
            className={this.respondentIsReady() ? '' : 'info-messages'}
            >
            <ChatWindow
              messages={this.mobileWebChatMessages()}
              chatTitle={t('Mobileweb mode')}
              readOnly
              scrollToBottom={false}
            />
          </div>
        }
      </div>
    )
  }

  render() {
    const { t, mode } = this.props
    const { disposition } = this.state
    return (
      <div>
        <Tooltip text={t('Stop simulation')}>
          <a className='btn-floating btn-large waves-effect waves-light red right mtop' onClick={(e) => this.stopSimulation(e)}>
            <i className='material-icons'>clear</i>
          </a>
        </Tooltip>
        <ConfirmationModal modalId='survey_stop_simulation_modal' ref='stopSimulationModal' confirmationText={t('Stop')} header={t('Stop simulation')} showCancel />
        {
          mode == 'mobileweb'
          ? this.mobileWebSimulation()
          : (
            <div className='row'>
              <div className='col s12 m4'>
                <DispositionChart disposition={disposition} />
              </div>
              <div className='col s12 m8'>
                {this.stepsComponent()}
              </div>
            </div>
          )
        }
      </div>
    )
  }
}

SurveySimulation.propTypes = {
  t: PropTypes.func,
  dispatch: PropTypes.func,
  router: PropTypes.object,
  projectId: PropTypes.string,
  surveyId: PropTypes.string,
  survey: PropTypes.object,
  questionnaire: PropTypes.object,
  mode: PropTypes.string
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    surveyId: ownProps.params.surveyId,
    survey: state.survey.data,
    questionnaire: state.questionnaire.data,
    mode: ownProps.params.mode
  }
}

export default translate()(withRouter(connect(mapStateToProps)(SurveySimulation)))
