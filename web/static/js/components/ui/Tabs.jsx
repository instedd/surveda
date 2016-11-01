import React, { Component, PropTypes } from 'react'

export class Tabs extends Component {
  static propTypes = {
    children: PropTypes.node,
    id: PropTypes.string.isRequired
  }

  componentDidMount() {
    $(this.refs.node).tabs()
  }

  render() {
    const { children, id } = this.props
    return (
      <nav id='BottomNav'>
        <div className='nav-wrapper'>
          <div className='row'>
            <div className='col s12 m11 l8'>
              <ul id={id} className='tabs' key='foo' ref='node'>
                {children}
              </ul>
            </div>
          </div>
        </div>
      </nav>
    )
  }
}
