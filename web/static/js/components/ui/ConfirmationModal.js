import React, { Component, PropTypes } from 'react'
import { Modal } from '.'

export class ConfirmationModal extends Component {
  render() {
    const { showLink, linkText, header, modalText, confirmationText, onNo, onConfirm, modalId, style, showCancel = false } = this.props

    let cancelLink = null
    if (showCancel) {
      cancelLink = <a href='#!' className=' modal-action modal-close waves-effect waves-green btn-flat'>Cancel</a>
    }

    let noLink = null
    if (onNo) {
      noLink = <a href='#!' onClick={onNo} className=' modal-action modal-close waves-effect waves-green btn-flat'>No</a>
    }

    return (
      <div>
        <Modal id={modalId} style={style} showLink={showLink} linkText={linkText}>
          <div className='modal-content'>
            <h4>{header}</h4>
            <p>{modalText}</p>
          </div>
          <div className='modal-footer'>
            {cancelLink}
            {noLink}
            <a href='#!' className=' modal-action modal-close waves-effect waves-green btn-flat' onClick={onConfirm}>{confirmationText}</a>
          </div>
        </Modal>
      </div>
    )
  }
}

ConfirmationModal.propTypes = {
  showLink: PropTypes.bool,
  showCancel: PropTypes.bool,
  linkText: PropTypes.string,
  header: PropTypes.string.isRequired,
  modalText: PropTypes.string.isRequired,
  confirmationText: PropTypes.string.isRequired,
  onConfirm: PropTypes.func.isRequired,
  onNo: PropTypes.func,
  modalId: PropTypes.string.isRequired,
  style: PropTypes.object
}
