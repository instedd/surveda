import React, { Component, PropTypes } from 'react'
import { withRouter } from 'react-router'
import { uniqueId } from 'lodash'

class TabLinkClass extends Component {
  constructor(props) {
    super(props)
    this.tabLinkId = uniqueId('TabLink')
  }

  componentDidUpdate() {
    const { tabId } = this.props
    if (this.isActive()) {
      $(`#${tabId}`).tabs('select_tab', this.tabLinkId)
    }
  }

  isActive() {
    const { to, router } = this.props
    return router.isActive(to, true)
  }

  render() {
    const { children, to, router } = this.props
    const className = this.isActive() ? 'active' : ''
    const clickHandler = () => {
      router.push(to)
    }

    return (
      <li className='tab col'>
        <a href={`#${this.tabLinkId}`} onClick={clickHandler} className={className}>{children}</a>
      </li>
    )
  }
}

TabLinkClass.propTypes = {
  children: PropTypes.node,
  to: PropTypes.string.isRequired,
  tabId: PropTypes.string.isRequired,
  router: PropTypes.object
}

export const TabLink = withRouter(TabLinkClass)
