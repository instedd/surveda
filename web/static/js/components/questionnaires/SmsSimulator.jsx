// @flow
import React, { Component } from 'react'
import { withRouter } from 'react-router'
import * as questionnaireActions from '../../actions/questionnaire'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import { startSmsSimulation, messageSmsSimulation } from '../../api.js'
import ChatWindow from './ChatWindow'
import DispositionChart from './DispositionChart'

type Props = {
  respondentId: string,
  messages: Array<string>,
  projectId: number,
  questionnaireId: number,
  questionnaireActions: Object
}

type State = {
  messages: Array<Object>,
  disposition: string,
  respondentId: string
}

class SmsSimulator extends Component<Props, State> {

  state = {
    messages: [],
    disposition: '',
    respondentId: ''
  }

  componentWillMount() {
    const { projectId, questionnaireId } = this.props

    if (projectId && questionnaireId) {
      this.props.questionnaireActions.fetchQuestionnaireIfNeeded(projectId, questionnaireId)
      startSmsSimulation(projectId, questionnaireId).then(result => {
        this.setState({ messages: result.messagesHistory, respondentId: result.respondentId, disposition: result.disposition })
      })
    }
  }

  handleATMessage = message => {
    const { projectId, questionnaireId } = this.props
    const { respondentId } = this.state

    this.addMessage(message)
    messageSmsSimulation(projectId, questionnaireId, respondentId, message.body).then(result => {
      this.setState({ messages: result.messagesHistory, disposition: result.disposition })
    })
  }

  addMessage = msg => {
    this.setState({ messages: [...this.state.messages, msg] })
  }

  render() {
    const { messages, disposition } = this.state
    if (messages.length) {
      return <div className='simulator-container'>
        <div className='col s12 m4'>
          <DispositionChart disposition={disposition} />
        </div>
        <div className='col s12 m4' />
        <div className='col s12 m4'>
          <ChatWindow messages={messages} onSendMessage={this.handleATMessage} chatTitle={'SMS mode'} />
        </div>
      </div>
    } else {
      return <div>Loading</div>
    }
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: parseInt(ownProps.params.projectId),
  questionnaireId: parseInt(ownProps.params.questionnaireId)
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(SmsSimulator))
