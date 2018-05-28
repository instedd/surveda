import React, { Component } from 'react'

type Props = {
  children: any,
  title: string,
  index: number,
  randomize: boolean
};
class Section extends Component {
  props: Props;

  toggleRandomize(index, checked) {
  }

  render() {
    const { title, index, randomize } = this.props
    return (
      <div className='section-container'>
        <div className='section-container-header'>
          <div className='switch'>
            <label>
              <input type='checkbox' checked={randomize} onChange={() => this.toggleRandomize(index, randomize)} />
              <span className='lever' />
              Randomize
            </label>
          </div>
          <div className='section-number'>{title}</div>
          <a href='#' className='close-section'>
            <i className='material-icons'>close</i>
          </a>
        </div>
        {this.props.children}
      </div>
    )
  }
}

export default Section
