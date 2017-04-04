// @flow
import React, { Component } from 'react'
import { Modal } from './Modal'

type Props = {
  showLink?: boolean,
  showCancel?: boolean,
  linkText?: string,
  header?: string,
  modalText?: any,
  confirmationText?: string,
  onConfirm?: Function,
  onNo?: Function,
  modalId?: string,
  children?: any,
  style?: Object
};

export class ConfirmationModal extends Component {
  props: Props
  state: Props

  constructor(props: Props) {
    super()
    this.state = props
  }

  componentWillReceiveProps(nextProps: Props) {
    var newState: $Shape<Props> = {}
    for (var variable in nextProps) {
      if (nextProps.hasOwnProperty(variable) && nextProps[variable]) {
        newState[variable] = nextProps[variable]
      }
    }
    this.setState(newState)
  }

  open(props: ?$Shape<Props>) {
    const modal: Modal = this.refs.modal

    if (props) {
      this.setState(props)
    }

    modal.open()
  }

  render() {
    const { showLink, linkText, header, modalText, confirmationText, onNo, onConfirm, modalId, style, children, showCancel = false } = this.state

    let cancelLink = null
    if (showCancel) {
      const onCancelClick = (e) => {
        e.preventDefault()
      }
      cancelLink = <a href='#!' onClick={onCancelClick} className='modal-action modal-close waves-effect waves-green btn-flat'>Cancel</a>
    }

    let noLink = null
    if (onNo) {
      const onNoClick = (e) => {
        e.preventDefault()
        onNo()
      }
      noLink = <a href='#!' onClick={onNoClick} className='modal-action modal-close waves-effect waves-green btn-flat'>No</a>
    }

    const onConfirmClick = (e) => {
      e.preventDefault()
      if (onConfirm) {
        onConfirm()
      }
    }

    var content
    if (typeof modalText === 'string') {
      content = <p>{modalText}</p>
    } else if (children) {
      content = children
    } else {
      content = modalText
    }

    return (
      <Modal id={modalId} ref='modal' style={style} showLink={showLink} linkText={linkText}>
        <div className='modal-content'>
          <h4>{header}</h4>
          {content}
        </div>
        <div className='modal-footer'>
          {cancelLink}
          {noLink}
          <a href='#!' className='modal-action modal-close waves-effect waves-green btn-flat' onClick={onConfirmClick}>{confirmationText}</a>
        </div>
      </Modal>
    )
  }
}
