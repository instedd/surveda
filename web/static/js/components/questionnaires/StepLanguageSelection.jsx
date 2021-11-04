import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/questionnaire'
import { Input } from 'react-materialize'
import iso6393 from 'iso-639-3'
import { Card } from '../ui'
import { translate } from 'react-i18next'

class StepLanguageSelection extends Component {
  translateLangCode(code) {
    const language = iso6393.find((lang) => lang.iso6391 == code || lang.iso6393 == code)
    return language.name
  }

  changeLanguageOrder(choice, event) {
    const { dispatch } = this.props
    event.preventDefault()
    dispatch(actions.reorderLanguages(choice, event.target.value))
  }

  render() {
    const { step, readOnly, t } = this.props
    const { languageChoices } = step

    let selectOptions = languageChoices.map((choice, index) =>
      <option key={index} id={index} value={index + 1}>
        {index + 1}
      </option>
    )

    return (
      <div>
        <h5>Options</h5>
        <p><b>{t('Choose a key for each language')}</b></p>
        <Card>
          <div className='card-table'>
            <table className='responses-table'>
              <thead>
                <tr>
                  <th style={{width: '80%'}}>{t('Language')}</th>
                  <th style={{width: '20%'}}>{t('Key')}</th>
                </tr>
              </thead>
              <tbody>
                { languageChoices.map((choice, index) =>
                  <tr key={`${choice}${index}`}>
                    <td>
                      {this.translateLangCode(choice)}
                    </td>
                    <td>
                      <Input s={8} type='select'
                        disabled={readOnly}
                        onChange={e => this.changeLanguageOrder(choice, e)}
                        defaultValue={index + 1}
                        >
                        {selectOptions}
                      </Input>
                    </td>
                  </tr>
                  )}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    )
  }
}

StepLanguageSelection.propTypes = {
  dispatch: PropTypes.func,
  t: PropTypes.func,
  step: PropTypes.object.isRequired,
  readOnly: PropTypes.bool
}

export default translate()(connect()(StepLanguageSelection))
