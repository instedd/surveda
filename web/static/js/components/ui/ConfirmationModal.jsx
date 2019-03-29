// @flow
import React, { Component } from 'react'
import { Modal } from './Modal'
import { I18n } from 'react-i18next'

type Props = {
  showLink?: boolean,
  showCancel?: boolean,
  linkText?: string,
  header?: string,
  modalText?: any,
  confirmationText?: string,
  noText?: string,
  onConfirm?: Function,
  onNo?: Function,
  modalId?: string,
  children?: any,
  style?: Object,
  initOptions?: any,
};

export class ConfirmationModal extends Component<Props, Props> {
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
    this.setState({ disabled: false, ...newState })
  }

  open(props: ?$Shape<Props>) {
    const modal: Modal = this.refs.modal

    if (props) {
      this.setState(props)
    }

    modal.open()
  }

  close() {
    const modal: Modal = this.refs.modal
    modal.close()
  }

  render() {
    const { disabled, showLink, linkText, header, modalText, confirmationText, onNo, onConfirm, modalId, style, children, showCancel = false, initOptions } = this.state
    let { noText } = this.state
    if (!noText) noText = 'No'

    let cancelLink = null
    if (showCancel) {
      const onCancelClick = (e) => {
        e.preventDefault()
      }
      cancelLink = <I18n>
        {
          t => (
            <a href='#!' disabled={disabled} onClick={onCancelClick} className='modal-action modal-close waves-effect waves-green btn-flat'>{t('Cancel')}</a>
          )
        }
      </I18n>
    }

    let noLink = null
    if (onNo) {
      const onNoClick = (e) => {
        e.preventDefault()
        onNo()
      }
      noLink = <a href='#!' disabled={disabled} onClick={onNoClick} className='modal-action modal-close waves-effect waves-green btn-flat'>{noText}</a>
    }

    const onConfirmClick = async (e) => {
      e.preventDefault()
      if (!onConfirm) return;
      const res = await onConfirm()
      res !== false && this.refs.modal.close()
    }

    var content
    if (typeof modalText === 'string') {
      content = <p>{modalText}</p>
    } else if (children) {
      content = children
    } else {
      content = modalText
    }

    let footer = null
    if (cancelLink || noLink || onConfirm || confirmationText) {
      footer = (
        <div className='modal-footer'>
          {cancelLink}
          {noLink}
          <a disabled={disabled} href='#!' className='modal-action waves-effect waves-green btn-flat' onClick={onConfirmClick}>{confirmationText}</a>
        </div>
      )
    }

    return (
      <Modal id={modalId} ref='modal' style={style} showLink={showLink} linkText={linkText} initOptions={initOptions}>
        <div className='modal-content'>
          <h4>{header}</h4>
          {content}
        </div>
        {footer}
      </Modal>
    )
  }
}
