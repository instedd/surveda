// @flow
import React, { Component } from 'react'
import { withRouter } from 'react-router'
import * as questionnaireActions from '../../actions/questionnaire'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import { startSimulation, messageSimulation } from '../../api.js'
import ChatWindow from './ChatWindow'
import DispositionChart from './DispositionChart'
import SimulationSteps from './SimulationSteps'

type Props = {
  projectId: number,
  questionnaireId: number,
  questionnaireActions: Object,
  questionnaire: Object
}

type ChatMessage = {
  type: string,
  body: string
}

type Submission = {
  id: string, // stepId
  response: ?string
}

type Simulation = {
  messagesHistory: Array<ChatMessage>,
  submissions: Array<Submission>,
  simulationStatus: string,
  disposition: string,
  respondentId: string,
  currentStep: string
}

type State = {
  simulation: ?Simulation
}

class QuestionnaireSimulation extends Component<Props, State> {
  state = {
    simulation: null
  }

  componentWillMount() {
    const { projectId, questionnaireId, mode } = this.props

    if (projectId && questionnaireId) {
      this.props.questionnaireActions.fetchQuestionnaireIfNeeded(projectId, questionnaireId)
      startSimulation(projectId, questionnaireId, mode).then(result => {
        this.setState({ simulation: result })
      })
    }
  }

  handleMessageResult = result => {
    const { simulation } = this.state
    // When the simulation expires we avoid refreshing (and so, erasing) the current state
    // So we only update the simulation status to expired
    // This allow us to handle this particular situation properly
    const newSimulation = result.simulationStatus == 'expired'
      ? {
        ...simulation,
        simulationStatus: 'expired'
      }
      : result
    this.setState({ simulation: newSimulation })
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
    const { questionnaire } = this.props
    const { simulation } = this.state
    const simulationIsAvailable = simulation && ['active', 'ended', 'expired'].includes(simulation.simulationStatus)
    const simulationIsExpired = simulation && simulation.simulationStatus == 'expired'
    const simulationIsActive = simulation && simulation.simulationStatus == 'active'
    const renderError = msg => <div className='error'>{msg}</div>
    const header = <header>
      {
        simulation && questionnaire
        ? simulationIsAvailable
          ? simulationIsExpired
            ? renderError('This simulation is expired. Please refresh to start a new one')
            : null
          : renderError('This simulation isn\'t available. Please refresh')
        : 'Loading'
      }
    </header>
    const main = <main>
      {
        simulation && questionnaire && simulationIsAvailable
        ? <div>
          <div className='col s12 m4'>
            <DispositionChart disposition={simulation.disposition} />
          </div>
          <div className='col s12 m4'>
            <SimulationSteps steps={questionnaire.steps}
              currentStepId={simulation.currentStep}
              submissions={simulation.submissions}
            />
          </div>
          <div className='col s12 m4'>
            <ChatWindow messages={simulation.messagesHistory} onSendMessage={this.handleATMessage} chatTitle={'SMS mode'} readOnly={!simulationIsActive} />
          </div>
        </div>
        : null
      }
    </main>

    return <div className='simulator-container'>
      {header}
      {main}
    </div>
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  questionnaireId: parseInt(ownProps.params.questionnaireId),
  mode: ownProps.params.mode,
  questionnaire: state.questionnaire.data
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QuestionnaireSimulation))
