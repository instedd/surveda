import React, { Component } from 'react'
import { connect } from 'react-redux'
import { InputWithLabel, Card } from '../ui'
import * as actions from '../../actions/questionnaire'

class QuotaCompletedMsg extends Component {
  constructor(props) {
    super(props)
    this.state = {
      editing: false
    }
    this.quotaCompletedMsgChanged = this.quotaCompletedMsgChanged.bind(this)
    this.handleClick = this.handleClick.bind(this)
  }

  handleClick() {
    this.setState({editing: !this.state.editing})
  }

  quotaCompletedMsgChanged(e, mode) {
    const { dispatch } = this.props
    e.preventDefault()
    switch (mode) {
      case 'sms':
        dispatch(actions.setSmsQuotaCompletedMsg(e.target.value))
        break
      case 'ivr':
        dispatch(actions.setIvrQuotaCompletedMsg(e.target.value))
        break
    }
  }

  render() {
    const { questionnaire } = this.props

    let quotaCompletedMsgs = questionnaire.modes.map((mode) => {
      const value = questionnaire.quotaCompletedMsg && questionnaire.quotaCompletedMsg[questionnaire.defaultLanguage][mode] ? questionnaire.quotaCompletedMsg[questionnaire.defaultLanguage][mode] : ''

      return (
        <div className='row' key={`quota-completed-${mode}`}>
          <div className='input-field'>
            <InputWithLabel value={value} label={`${mode == 'sms' ? 'SMS' : 'Phone'} message`}>
              <input
                type='text'
                onChange={e => this.quotaCompletedMsgChanged(e, mode)}
              />
            </InputWithLabel>
          </div>
        </div>
      )
    })

    if (this.state.editing) {
      return (
        <Card>
          <div onClick={this.handleClick} >
            <i className='material-icons left'>pie_chart</i>
            Quota completed message
            <i className='material-icons'>expand_less</i>
          </div>
          <div>
            {quotaCompletedMsgs}
          </div>
        </Card>
      )
    } else {
      return (
        <div onClick={this.handleClick} >
          <i className='material-icons left'>pie_chart</i>
          Quota completed messages
          <i className='material-icons right grey-text'>expand_more</i>
        </div>
      )
    }
  }
}

const mapStateToProps = (state) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(QuotaCompletedMsg)
