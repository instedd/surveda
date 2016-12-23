import React, { Component, PropTypes } from 'react'
import { EditableTitleLabel, Card } from '../ui'

class StepCard extends Component {

  render() {
    const { onCollapse, step, children, icon, stepTitle, onTitleSubmit } = this.props

    return (
      <Card key={step.id}>
        <ul className='collection collection-card'>
          <li className='collection-item input-field header'>
            <div className='row'>
              <div className='col s12'>
                {icon}
                <EditableTitleLabel className='editable-field' title={stepTitle} emptyText='Untitled question' onSubmit={value => onTitleSubmit(value)} />
                <a href='#!'
                  className='collapse right'
                  onClick={e => {
                    e.preventDefault()
                    onCollapse()
                  }}>
                  <i className='material-icons'>expand_less</i>
                </a>
              </div>
            </div>
          </li>
          {children}
        </ul>
      </Card>
    )
  }
}

StepCard.propTypes = {
  icon: PropTypes.object.isRequired,
  stepTitle: PropTypes.string.isRequired,
  step: PropTypes.object.isRequired,
  onTitleSubmit: PropTypes.func.isRequired,
  children: PropTypes.node,
  onCollapse: PropTypes.func.isRequired
}

export default StepCard
