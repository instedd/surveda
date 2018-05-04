// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'

type Props = {
  progress: number,
  title: string
};

class Header extends Component<Props> {
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

Header.contextTypes = {
  primaryColor: PropTypes.string,
  secondaryColor: PropTypes.string
}

const mapStateToProps = (state) => ({
  progress: state.step.progress,
  title: state.step.title
})

export default connect(mapStateToProps)(Header)
