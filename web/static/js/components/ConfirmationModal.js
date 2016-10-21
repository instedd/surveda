import React, { Component, PropTypes } from 'react'

class ConfirmationModal extends Component {
  componentDidMount() {
    $(document).ready(function() {
      $('.modal-trigger').leanModal()
    })
  }

  render() {
    const { showLink, linkText, header, modalText, confirmationText, onConfirm, modalId, style } = this.props

    let modalLink = null
    if (showLink) {
      modalLink = (<a className='modal-trigger' href={`#${modalId}`}>{linkText}</a>)
    }

    return (
      <div>
        {modalLink}
        <div id={modalId} className='modal' style={style}>
          <div className='modal-content'>
            <h4>{header}</h4>
            <p>{modalText}</p>
          </div>
          <div className='modal-footer'>
            <a href='#!' className=' modal-action modal-close waves-effect waves-green btn-flat' onClick={onConfirm}>{confirmationText}</a>
            <a href='#!' className=' modal-action modal-close waves-effect waves-green btn-flat'>Cancel</a>
          </div>
        </div>
      </div>
    )
  }
}

ConfirmationModal.propTypes = {
  showLink: PropTypes.bool,
  linkText: PropTypes.string,
  header: PropTypes.string.isRequired,
  modalText: PropTypes.string.isRequired,
  confirmationText: PropTypes.string.isRequired,
  onConfirm: PropTypes.func.isRequired,
  modalId: PropTypes.string.isRequired
}

export default ConfirmationModal

