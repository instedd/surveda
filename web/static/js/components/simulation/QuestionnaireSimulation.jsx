// @flow
import React, { Component } from 'react'
import { withRouter, browserHistory } from 'react-router'
import * as questionnaireActions from '../../actions/questionnaire'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import * as routes from '../../routes'
import { Tooltip } from '../ui'
import { startSimulation, messageSimulation, fetchSimulation } from '../../api.js'
import ChatWindow from './ChatWindow'
import VoiceWindow from './VoiceWindow'
import MobileWebWindow from './MobileWebWindow'
import DispositionChart from './DispositionChart'
import SimulationSteps from './SimulationSteps'
import { translate } from 'react-i18next'

type ChatMessage = {
  type: string,
  body: string
}

type Submission = {
  stepId: string,
  response: ?string
}

type IVRPrompt = {
  text: string,
  audioSource: string,
  audioId: string
}

type Simulation = {
  messagesHistory: Array<ChatMessage>,
  prompts: Array<IVRPrompt>,
  submissions: Array<Submission>,
  simulationStatus: string,
  disposition: string,
  respondentId: string,
  currentStep: string,
  questionnaire: Questionnaire,
  indexUrl: string
}

type Props = {
  projectId: number,
  questionnaireId: number,
  mode: string,
  questionnaireActions: Object,
  t: Function,
  router: Object
}

type State = {
  simulation: ?Simulation,
  isSimulationTerminated: boolean
}

class QuestionnaireSimulation extends Component<Props, State> {
  _onMessage: Function // MessageEvent<{ simulationChanged: boolean }> => void

  state = {
    simulation: null,
    isSimulationTerminated: false
  }

  componentDidMount() {
    const { projectId, questionnaireId, mode } = this.props

    browserHistory.listen(this.onRouteChange)

    if (mode == 'mobileweb') {
      this._onMessage = event => { this.onMessage(event) }
      window.addEventListener('message', this._onMessage)
    }

    if (projectId && questionnaireId) {
      this.fetchQuestionnaireForTitle()

      if (['sms', 'ivr', 'mobileweb'].includes(mode)) {
        startSimulation(projectId, questionnaireId, mode).then(result => {
          this.setState({simulation: result})
        })
      }
    }
  }

  componentWillUnmount() {
    if (this._onMessage) {
      window.removeEventListener('message', this._onMessage)
    }
  }

  onRouteChange = () => {
    document.querySelectorAll('.toast').forEach(t => t.remove())
  }

  /**
   * This component doesn't do this fetch for itself
   * The title component (rendered above) needs the questionnaire in the redux store
   */
  fetchQuestionnaireForTitle = () => {
    const { projectId, questionnaireId } = this.props
    this.props.questionnaireActions.fetchQuestionnaireIfNeeded(projectId, questionnaireId)
  }

  // Callback for the mobileweb simulator running in an iframe.
  onMessage(event) {
    const { mode } = this.props
    const { simulation } = this.state

    if (event.data.simulationChanged && simulation) {
      const { projectId, questionnaireId } = this.props
      return fetchSimulation(projectId, questionnaireId, simulation.respondentId, mode).then(result => {
        this.onSimulationChanged(result)
      })
    }
  }

  onSimulationChanged = result => {
    if (this.state.isSimulationTerminated) return

    const { simulation } = this.state
    const { t } = this.props
    const { simulationStatus } = result
    const isSimulationTerminated = simulationStatus == 'expired' || simulationStatus == 'ended'
    let newSimulation

    if (isSimulationTerminated) {
      switch (simulationStatus) {
        case 'expired':
          window.Materialize.toast(t('This simulation is expired. Please refresh to start a new one'))
          break
        case 'ended':
          window.Materialize.toast(t('This simulation is ended. Please refresh to start a new one'))
          break
      }
    }

    if (simulationStatus == 'expired') {
      // When the simulation expires we avoid refreshing (and so, erasing) the current state
      // So we only update the simulation status and we send a message to the end user
      // This allow us to handle this particular situation properly
      newSimulation = {
        ...simulation,
        simulationStatus
      }
    } else {
      newSimulation = {
        ...simulation,
        messagesHistory: result.messagesHistory, // mode=sms
        prompts: result.prompts, // mode=ivr
        submissions: result.submissions,
        simulationStatus,
        disposition: result.disposition,
        currentStep: result.currentStep
      }
    }

    this.setState({
      simulation: newSimulation,
      isSimulationTerminated
    })
  }

  handleATMessage = message => {
    const { projectId, questionnaireId, mode } = this.props
    const { simulation } = this.state
    if (simulation) {
      this.addMessage(message)
      messageSimulation(projectId, questionnaireId, simulation.respondentId, message.body, mode).then(result => {
        this.onSimulationChanged(result)
      })
    }
  }

  addMessage(message) {
    const { simulation } = this.state

    if (simulation && simulation.messagesHistory) {
      this.setState({
        simulation: {
          ...simulation,
          messagesHistory: [...simulation.messagesHistory, message]
        }
      })
    }
  }

  closeSimulation = () => {
    const { router, projectId, questionnaireId } = this.props
    router.push(routes.editQuestionnaire(projectId, questionnaireId))
  }

  render() {
    const { simulation } = this.state
    const { mode, t } = this.props

    if (!simulation) return <div>{t('Loading...')}</div>

    const simulationIsActive = simulation && simulation.simulationStatus == 'active'
    const closeSimulationButton = (
      <div>
        <Tooltip text='Close Simulation'>
          <a key='one' className='btn-floating btn-large waves-effect waves-light red right mtop' href='#' onClick={this.closeSimulation}>
            <i className='material-icons'>close</i>
          </a>
        </Tooltip>
      </div>
    )
    const phoneWindow = () => {
      switch (mode) {
        case 'sms':
          return <ChatWindow messages={simulation.messagesHistory} onSendMessage={this.handleATMessage} chatTitle={'SMS mode'} readOnly={!simulationIsActive} scrollToBottom />
        case 'ivr':
          return <VoiceWindow voiceTitle={'Voice mode'} prompts={simulation.prompts} onSendMessage={this.handleATMessage} onCloseSimulation={this.closeSimulation} readOnly={!simulationIsActive} />
        case 'mobileweb':
          return <MobileWebWindow indexUrl={simulation.indexUrl} />
      }
    }

    return <div>
      {closeSimulationButton}
      <div className='quex-simulation-container'>
        <DispositionChart disposition={simulation.disposition} />
        <SimulationSteps steps={simulation.questionnaire.steps}
          currentStepId={simulation.currentStep}
          submissions={simulation.submissions}
          simulationIsEnded={simulation.simulationStatus == 'ended'}
        />
        {phoneWindow()}
      </div>
    </div>
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  questionnaireId: parseInt(ownProps.params.questionnaireId),
  mode: ownProps.params.mode
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default translate()(withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireSimulation)))
