// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'

class Header extends Component {
  render() {
    const { progress, title } = this.props
    const percent = `${progress}%`

    return (
      <header>
        <nav style={{'backgroundColor': this.context.primaryColor}}>
          <h1 dangerouslySetInnerHTML={{__html: title}} />
          <div className='progressBar'>
            <span style={{ width: percent, backgroundColor: this.context.secondaryColor }} />
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

Header.contextTypes = {
  primaryColor: PropTypes.string,
  secondaryColor: PropTypes.string
}

const mapStateToProps = (state) => ({
  progress: state.step.progress,
  title: state.step.title
})

export default connect(mapStateToProps)(Header)
