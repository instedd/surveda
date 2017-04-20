// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'

class Header extends Component {
  render() {
    const { progress } = this.props
    const percent = `${progress}%`

    return (
      <header>
        <nav>
          <div className='progressBar'>
            <span style={{ width: percent }} />
          </div>
        </nav>
      </header>
    )
  }
}

Header.propTypes = {
  progress: PropTypes.number.isRequired
}

const mapStateToProps = (state) => ({
  progress: state.step.progress
})

export default connect(mapStateToProps)(Header)
