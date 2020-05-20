// @flow
import React, { Component } from 'react'
import { withRouter, browserHistory } from 'react-router'
import { connect } from 'react-redux'
import { startSimulation, messageSimulation } from '../../api.js'
import ChatWindow from './ChatWindow'
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

type Simulation = {
  messagesHistory: Array<ChatMessage>,
  submissions: Array<Submission>,
  simulationStatus: string,
  disposition: string,
  respondentId: string,
  currentStep: string,
  questionnaire: Questionnaire
}

type Props = {
  projectId: number,
  questionnaireId: number,
  mode: string,
  t: Function
}

type State = {
  simulation: ?Simulation
}

const QuestionnaireSimulation = translate()(class extends Component<Props, State> {
  state = {
    simulation: null
  }

  componentDidMount = () => {
    browserHistory.listen(this.onRouteChange)
  }

  onRouteChange = () => {
    document.querySelectorAll('.toast').forEach(t => t.remove())
  }

  componentWillMount() {
    const { projectId, questionnaireId, mode } = this.props
    if (projectId && questionnaireId) {
      // We only support SMS for now
      if (mode == 'sms') {
        startSimulation(projectId, questionnaireId, mode).then(result => {
          this.setState({ simulation: {
            messagesHistory: result.messagesHistory,
            submissions: result.submissions,
            simulationStatus: result.simulationStatus,
            disposition: result.disposition,
            respondentId: result.respondentId,
            currentStep: result.currentStep,
            questionnaire: result.questionnaire
          }})
        })
      }
    }
  }

  handleMessageResult = result => {
    const { simulation } = this.state
    const { t } = this.props
    if (result.simulationStatus == 'expired') {
      // When the simulation expires we avoid refreshing (and so, erasing) the current state
      // So we only update the simulation status and we send a message to the end user
      // This allow us to handle this particular situation properly
      window.Materialize.toast(t('This simulation is expired. Please refresh to start a new one'))
      this.setState({
        simulation: {
          ...simulation,
          simulationStatus: result.simulationStatus
        }
      })
    } else {
      if (result.simulationStatus == 'ended') {
        window.Materialize.toast(t('This simulation is ended. Please refresh to start a new one'))
      }
      this.setState({
        simulation: {
          ...simulation,
          messagesHistory: result.messagesHistory,
          submissions: result.submissions,
          simulationStatus: result.simulationStatus,
          disposition: result.disposition,
          currentStep: result.currentStep
        }
      })
    }
  }

  handleATMessage = message => {
    const { projectId, questionnaireId } = this.props
    const { simulation } = this.state
    if (simulation) {
      this.addMessage(message)
      messageSimulation(projectId, questionnaireId, simulation.respondentId, message.body).then(result => {
        this.handleMessageResult(result)
      })
    }
  }

  addMessage = message => {
    const { simulation } = this.state
    if (simulation) {
      this.setState({
        simulation: {
          ...simulation,
          messagesHistory: [
            ...simulation.messagesHistory,
            message
          ]
        }
      })
    }
  }

  render() {
    const { simulation } = this.state
    const simulationIsActive = simulation && simulation.simulationStatus == 'active'
    return <div className='simulator-container'>
      {
        simulation
        ? <div>
          <div className='col s12 m4'>
            <DispositionChart disposition={simulation.disposition} />
          </div>
          <div className='col s12 m4'>
            <SimulationSteps steps={simulation.questionnaire.steps}
              currentStepId={simulation.currentStep}
              submissions={simulation.submissions}
              simulationIsEnded={simulation.simulationStatus == 'ended'}
            />
          </div>
          <div className='col s12 m4'>
            <ChatWindow messages={simulation.messagesHistory} onSendMessage={this.handleATMessage} chatTitle={'SMS mode'} readOnly={!simulationIsActive} />
          </div>
        </div>
        : 'Loading'
      }
    </div>
  }
})

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  questionnaireId: parseInt(ownProps.params.questionnaireId),
  mode: ownProps.params.mode
})

export default withRouter(connect(mapStateToProps)(QuestionnaireSimulation))
