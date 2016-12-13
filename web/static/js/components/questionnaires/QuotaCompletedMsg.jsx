import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { InputWithLabel, Card } from '../ui'
import * as actions from '../../actions/questionnaire'

class QuotaCompletedMsg extends Component {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    questionnaire: PropTypes.object
  }

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

    if (!questionnaire) {
      return <div>Loading...</div>
    }

    let quotaCompletedMsgs = questionnaire.modes.map((mode) => {
      const quotaMsg = questionnaire.quotaCompletedMsg
      const defaultLang = questionnaire.defaultLanguage

      const value = quotaMsg && quotaMsg[defaultLang] && quotaMsg[defaultLang][mode] || ''

      return (
        <div className='row' key={`quota-completed-${mode}`}>
          <div className='input-field'>
            <InputWithLabel value={value} label={`${mode == 'sms' ? 'SMS' : 'Voice'} message`} id={`${mode == 'sms' ? 'quota_sms' : 'quota_voice'}`}>
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
          <ul className='collection collection-card dark'>
            <li className='collection-item header'>
              <div className='row'>
                <div className='col s12'>
                  <i className='material-icons left'>pie_chart</i>
                  <a className='page-title truncate'>
                    <span>Quota completed messages</span>
                  </a>
                  <a className='collapse right' href='#!' onClick={this.handleClick}>
                    <i className='material-icons'>expand_less</i>
                  </a>
                </div>
              </div>
            </li>
            <li className='collection-item'>
              <div>
                {quotaCompletedMsgs}
              </div>
            </li>
          </ul>
        </Card>
      )
    } else {
      return (
        <ul className='collapsible dark'>
          <li>
            <Card>
              <div className='card-content closed-step'>
                <a className='truncate' href='#!' onClick={this.handleClick}>
                  <i className='material-icons left'>pie_chart</i>
                  <span>Quota completed messages</span>
                  <i className='material-icons right grey-text'>expand_more</i>
                </a>
              </div>

            </Card>
          </li>
        </ul>
      )
    }
  }
}

const mapStateToProps = (state) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(QuotaCompletedMsg)
