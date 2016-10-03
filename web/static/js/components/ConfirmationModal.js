import React, { Component } from 'react'
import ReactDOM from 'react-dom'

export class ConfirmationModal extends Component {
  static propTypes = {
    linkText: React.PropTypes.string.isRequired,
    header: React.PropTypes.string.isRequired,
    modalText: React.PropTypes.string.isRequired,
    confirmationText: React.PropTypes.string.isRequired,
    onConfirm: React.PropTypes.func.isRequired,
    modalId: React.PropTypes.string.isRequired
  }

  componentDidMount() {
    $(document).ready(function(){
      $('.modal-trigger').leanModal();
    })
  }

  render() {
    const { showLink, linkText, header, modalText, confirmationText, onConfirm, modalId } = this.props

    return(
      <div>
        <ModalLink showLink={showLink} modalId={modalId} linkText={linkText} />

        <div id={modalId} className="modal">
          <div className="modal-content">
            <h4>{header}</h4>
            <p>{modalText}</p>
          </div>
          <div className="modal-footer">
            <a href="#!" className=" modal-action modal-close waves-effect waves-green btn-flat" onClick={onConfirm}>{confirmationText}</a>
          </div>
        </div>
      </div>
    )
  }
}

const ModalLink = ({showLink, modalId, linkText}) => {
  if (showLink){
    return (<a className="modal-trigger" href={`#${modalId}`}>{linkText}</a>)
  }
  return null
}
