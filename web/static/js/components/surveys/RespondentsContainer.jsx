import React, { PropTypes } from 'react'
import { translate, Trans } from 'react-i18next'

export const RespondentsContainer = translate()(({ children, t }) => {
  const onClick = (e) => { e.preventDefault(); window.open('/files/phone_numbers_example.csv') }
  const download = 'phone_numbers_example.csv'

  return (
    <div>
      <div className='row'>
        <div className='col s12'>
          <h4>{t('Upload your respondents list')}</h4>
          <p className='flow-text'>
            <Trans>Upload a CSV file like <a href='#' onClick={onClick} download={download}>this one</a> with your respondents. You can define how many of these respondents need to successfully answer the survey by setting up cutoff rules.</Trans>
          </p>
          <p>
            <b>
              { t('Uploading a CSV with respondent ids will disable incentive download') }
            </b>
          </p>
        </div>
      </div>
      <div className='row'>
        <div className='col s12'>
          {children}
        </div>
      </div>
    </div>
  )
})

RespondentsContainer.propTypes = {
  t: PropTypes.func,
  children: PropTypes.node
}
