import React, { Component, PropTypes } from 'react'
import { stepStoreValues } from '../../reducers/questionnaire'
import filter from 'lodash/filter'
import map from 'lodash/map'
import join from 'lodash/join'
import includes from 'lodash/includes'

export class QuotasModal extends Component {
  static propTypes = {
    showLink: PropTypes.bool,
    linkText: PropTypes.string,
    header: PropTypes.string.isRequired,
    survey: PropTypes.object.isRequired,
    questionnaire: PropTypes.object.isRequired,
    onConfirm: PropTypes.func.isRequired,
    modalId: PropTypes.string.isRequired,
    style: PropTypes.object
  }

  constructor(props) {
    super(props)
    this.state = {
      buckets: {},
      steps: {}
    }
    this.onSubmit = this.onSubmit.bind(this)
  }

  componentDidMount() {
    $(document).ready(function() {
      $('.modal').modal()
    })
  }

  onSubmit(e) {
    const selectedVars = map(filter(Object.keys(this.state.buckets), value =>
      this.state.buckets[value].checked
    ), (quotaVar) => ({
      var: quotaVar,
      steps: (this.state.steps[quotaVar] || '').value
    }))
    this.props.onConfirm(selectedVars)
  }

  render() {
    const { showLink, linkText, header, survey, questionnaire, modalId, style } = this.props

    this.state.buckets = {}

    let modalLink = null
    if (showLink) {
      modalLink = (<a className='modal-trigger' href={`#${modalId}`}>{linkText}</a>)
    }
    const storeValues = stepStoreValues(questionnaire)

    return (
      <div>
        {modalLink}
        <div id={modalId} className='modal card' style={style}>
          <div className='modal-content'>
            <div className='card-title header'>
              <h5>{header}</h5>
              <p>Choose the questionnaire answers you want to use to define quotas</p>
            </div>
            <div className='card-content'>
              {Object.keys(storeValues).map((storeValue) =>
                <div className='row' key={storeValue} >
                  <div className='col s12'>
                    { storeValues[storeValue].type == 'numeric'
                      ? <div className='question left'>
                        <div className='question-icon-label'>
                          <i className='material-icons v-middle left'>dialpad</i>
                          <span>{storeValue}</span>
                        </div>
                        <div className='question-value'>
                          <div className='input-field'>
                            <input type='text' ref={node => { this.state.steps[storeValue] = node }} />
                            <span className='small-text-bellow'>
                              Enter comma-separated values to create ranges like 5,10,20
                            </span>
                          </div>
                        </div>
                      </div>
                      : <div className='question left'>
                        <div className='question-icon-label'>
                          <i className='material-icons v-middle left'>list</i>
                          <span>{storeValue}</span>
                        </div>
                        <div className='question-value'>
                          {join(storeValues[storeValue].values, ', ')}
                        </div>
                      </div>
                    }
                    <div className='checkbox right'>
                      <input type='checkbox' className='filled-in' id={storeValue} defaultChecked={includes(survey.quotas.vars, storeValue)} ref={node => { this.state.buckets[storeValue] = node }} />
                      <label htmlFor={storeValue} />
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
          <div className='card-action'>
            <a href='#!' className='modal-action modal-close waves-effect waves-light blue btn-large' onClick={this.onSubmit}>DONE</a>
            <a href='#!' className='modal-action modal-close grey-text btn-link'>Cancel</a>
          </div>
        </div>
      </div>
    )
  }
}
