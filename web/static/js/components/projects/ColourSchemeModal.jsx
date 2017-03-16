import React, { Component, PropTypes } from 'react'
// import React, { Component } from 'react'
import { connect } from 'react-redux'
import { Modal } from '../ui'

export class ColourSchemeModal extends Component {
  render() {
    const { modalId } = this.props
    return (
      <Modal card id={modalId} >
        <div>
          Select colour scheme
        </div>
      </Modal>
    )
  }
}

ColourSchemeModal.propTypes = {
  modalId: PropTypes.string
}

const mapDispatchToProps = (dispatch) => ({
})

const mapStateToProps = (state) => ({
})

export default connect(mapStateToProps, mapDispatchToProps)(ColourSchemeModal)
