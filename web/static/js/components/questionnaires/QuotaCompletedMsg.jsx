import React, { Component } from 'react'
import { connect } from 'react-redux'
import { InputWithLabel, Card } from '../ui'
import * as actions from '../../actions/questionnaire'

class QuotaCompletedMsg extends Component {
  constructor(props) {
    super(props)
    this.quotaCompletedMsgChanged = this.quotaCompletedMsgChanged.bind(this)
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

    return (
      <Card>
        <i className='material-icons left'>pie chart</i>
        Quota completed message
        <div>
          {quotaCompletedMsgs}
        </div>
      </Card>
    )
  }
}

const mapStateToProps = (state) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(QuotaCompletedMsg)
