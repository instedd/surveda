import React, { Component, PropTypes } from 'react'
import classNames from 'classnames/bind'

export class Modal extends Component {
  componentDidMount() {
    $(this.refs.modal).modal()
  }

  render() {
    const { showLink, linkText, id, style, children, card = false } = this.props

    let modalLink = null
    if (showLink) {
      modalLink = (<a className='modal-trigger' href={`#${id}`}>{linkText}</a>)
    }

    return (
      <div>
        {modalLink}
        <div id={id} className={classNames({'modal': true, 'card': card})} style={style} ref='modal'>
          {children}
        </div>
      </div>
    )
  }
}

Modal.propTypes = {
  showLink: PropTypes.bool,
  card: PropTypes.bool,
  children: PropTypes.node,
  linkText: PropTypes.string,
  id: PropTypes.string.isRequired,
  style: PropTypes.object
}
