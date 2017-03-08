import React, { Component } from 'react'
import { connect } from 'react-redux'
import { Card } from '../ui'
import classNames from 'classnames'

class MobileWebSmsMessage extends Component {
  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  handleClick(e) {
    e.preventDefault()
    this.setState({editing: !this.state.editing})
  }

  stateFromProps(props, editing) {
    const { questionnaire } = props

    if (!questionnaire) {
      return {
        editing: editing,
        text: null
      }
    }

    return {
      editing,
      text: questionnaire.mobile_web_sms_message
    }
  }

  collapsed() {
    const hasErrors = false

    const iconClass = classNames({
      'material-icons left': true,
      'text-error': hasErrors
    })

    return (
      <ul className='collapsible dark'>
        <li>
          <Card>
            <div className='card-content closed-step'>
              <a className='truncate' href='#!' onClick={(e) => this.handleClick(e)}>
                <i className={iconClass}>phonelink</i>
                <span className={classNames({'text-error': hasErrors})}>Mobile Web SMS message</span>
                <i className={classNames({'material-icons right grey-text': true, 'text-error': hasErrors})}>expand_more</i>
              </a>
            </div>
          </Card>
        </li>
      </ul>
    )
  }

  expanded() {
    return (
      <div className='row'>
        <Card className='z-depth-0'>
          <ul className='collection collection-card dark'>
            <li className='collection-item header'>
              <div className='row'>
                <div className='col s12'>
                  <i className='material-icons left'>phonelink</i>
                  <a className='page-title truncate'>
                    <span>Mobile Web SMS message</span>
                  </a>
                  <a className='collapse right' href='#!' onClick={(e) => this.handleClick(e)}>
                    <i className='material-icons'>expand_less</i>
                  </a>
                </div>
              </div>
            </li>
            <li className='collection-item'>
              <div>
                Hola!
              </div>
            </li>
          </ul>
        </Card>
      </div>
    )
  }

  render() {
    const { questionnaire } = this.props
    if (!questionnaire) {
      return <div>Loading...</div>
    }

    if (this.state.editing) {
      return this.expanded(questionnaire)
    } else {
      return this.collapsed()
    }
  }
}

const mapStateToProps = (state, ownProps: Props) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(MobileWebSmsMessage)
