import React, { Component, PropTypes } from 'react'

export class Tabs extends Component {
  static propTypes = {
    children: PropTypes.node
  }
  componentDidMount() {
    $(this.refs.node).tabs()
  }

  render() {
    const { children } = this.props
    return (
      <nav id='BottomNav'>
        <div className='nav-wrapper'>
          <div className='row'>
            <div className='col s12 m11 l8'>
              <ul className='tabs' key='foo' ref='node'>
                {children}
              </ul>
            </div>
          </div>
        </div>
      </nav>
    )
  }
}
