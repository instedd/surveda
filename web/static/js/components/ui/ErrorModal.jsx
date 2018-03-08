import React, { Component, PropTypes } from 'react'
import { Modal } from '.'
import { render } from 'react-dom'
import { translate, I18nextProvider } from 'react-i18next'
import i18n from '../../i18next'

class ErrorModalComponent extends Component {
  componentDidMount() {
    this.refs.modal.open()
  }

  render() {
    const { error, errorId, t } = this.props

    return (
      <Modal card ref='modal' id='error-modal'>
        <div className='modal-content'>
          <div className='card-title header'>
            <h5>{t('Error details')}</h5>
            <p>{t('Please contact support for further assistance')}</p>
          </div>
          <div className='card-content'>
            <b>{error.message}</b>

            <h6>{t('Error ID:')}</h6>
            {errorId}

            <h6>{t('Call stack')}</h6>
            <pre>
              {error.stack}
            </pre>
          </div>
        </div>
        <div className='card-action'>
          <a href='#!' className=' modal-action modal-close btn-flat grey-text'>{t('Close')}</a>
        </div>
      </Modal>
    )
  }
}

ErrorModalComponent.propTypes = {
  t: PropTypes.func,
  error: PropTypes.object,
  errorId: PropTypes.string
}

export const ErrorModal = translate()(ErrorModalComponent)

export const showError = (errorId, error) => {
  const detailsContainer = document.createElement('div')
  document.body.append(detailsContainer)

  const detailsModal = (
    <I18nextProvider i18n={i18n}>
      <ErrorModal errorId={errorId} error={error} />
    </I18nextProvider>
  )

  render(detailsModal, detailsContainer)
}
