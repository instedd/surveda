// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'

class Header extends Component {
  render() {
    const { progress, title } = this.props
    const percent = `${progress}%`

    return (
      <header>
        <nav style={{'background-color': window.colorStyle.primary_color}}>
          <h1>{title}</h1>
          <div className='progressBar'>
            <span style={{ width: percent }} />
          </div>
        </nav>
      </header>
    )
  }
}

Header.propTypes = {
  progress: PropTypes.number.isRequired,
  title: PropTypes.string.isRequired
}

const mapStateToProps = (state) => ({
  progress: state.step.progress,
  title: state.step.title
})

export default connect(mapStateToProps)(Header)
