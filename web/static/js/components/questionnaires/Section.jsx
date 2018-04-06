import React, { PropTypes, Component } from 'react'

class Section extends Component {

  render() {
    return (
      <div className="section-container">
        <div className="section-container-header">
          <div className='switch'>
            <label>
              <input type='checkbox'/>
              <span className='lever' />
              Randomize
            </label>
          </div>
          <div className="section-number">Section 1</div>
          <a href="#" className="close-section">
            <i className="material-icons">close</i>
          </a>
        </div>
        {this.props.children}
      </div>
    )
  }
}

export default Section
