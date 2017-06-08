import React, { Component, PropTypes } from 'react'
import { Modal } from '.'
import { render } from 'react-dom'

export class ErrorModal extends Component {
  componentDidMount() {
    this.refs.modal.open()
  }

  render() {
    const { error, errorId } = this.props

    return (
      <Modal card ref='modal' id='error-modal'>
        <div className='modal-content'>
          <div className='card-title header'>
            <h5>Error details</h5>
            <p>Please contact support for further assistance</p>
          </div>
          <div className='card-content'>
            <b>{error.message}</b>

            <h6>Error ID:</h6>
            {errorId}

            <h6>Call stack</h6>
            <pre>
              {error.stack}
            </pre>
          </div>
        </div>
        <div className='card-action'>
          <a href='#!' className=' modal-action modal-close btn-flat grey-text'>CLOSE</a>
        </div>
      </Modal>
    )
  }
}

ErrorModal.propTypes = {
  error: PropTypes.object,
  errorId: PropTypes.string
}

export const showError = (errorId, error) => {
  const detailsContainer = document.createElement('div')
  document.body.append(detailsContainer)

  const detailsModal = <ErrorModal errorId={errorId} error={error} />
  render(detailsModal, detailsContainer)
}
