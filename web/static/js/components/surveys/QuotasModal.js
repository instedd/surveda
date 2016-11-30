import React, { Component, PropTypes } from 'react'
import { stepStoreValues } from '../../reducers/questionnaire'
import filter from 'lodash/filter'

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
      buckets: {}
    }
    this.onSubmit = this.onSubmit.bind(this)
  }

  componentDidMount() {
    $(document).ready(function() {
      $('.modal').modal()
    })
  }
  onSubmit(e) {
    const selectedVars = filter(Object.keys(this.state.buckets), value =>
      this.state.buckets[value].checked
    )
    this.props.onConfirm(selectedVars)
  }

  render() {
    const { showLink, linkText, header, survey, questionnaire, modalId, style } = this.props

    let modalLink = null
    if (showLink) {
      modalLink = (<a className='modal-trigger' href={`#${modalId}`}>{linkText}</a>)
    }

    return (
      <div>
        {modalLink}
        <div id={modalId} className='modal' style={style}>
          <div className='modal-content'>
            <h4>{header}</h4>
            {Object.keys(stepStoreValues(questionnaire)).map((storeValue) =>
              <div className='row' key={storeValue} >
                <div className='col s12'>
                  <i className='material-icons v-middle left'>list</i>
                  <span className='mode-label'>{storeValue}</span>
                  <div className='switch right'>
                    <label>
                      <input type='checkbox' checked={survey.quotas.buckets[storeValue]} ref={node => { this.state.buckets[storeValue] = node }} />
                      <span className='lever' />
                    </label>
                  </div>
                </div>
              </div>
            )}
          </div>
          <div className='modal-footer'>
            <a href='#!' className=' modal-action modal-close waves-effect waves-green btn-flat' onClick={this.onSubmit}>DONE</a>
            <a href='#!' className=' modal-action modal-close waves-effect waves-green btn-flat'>Cancel</a>
          </div>
        </div>
      </div>
    )
  }
}
