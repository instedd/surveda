// @flow
import React, { Component } from 'react'
import { translate } from 'react-i18next'
import classNames from 'classnames'

type Props = {
  disposition: string,
  t: Function
}

const immediatePast = {
  'registered': null,
  'queued': 'registered',
  'started': 'contacted',
  'interim partial': 'started',
  'completed': 'interim partial',
  'failed': 'queued',
  'contacted': 'queued',
  'unresponsive': 'contacted',
  'refused': 'started',
  'inteligible': 'started',
  'rejected': 'started',
  'breakoff': 'started',
  'partial': 'interim partial'
}

class DispositionChart extends Component<Props> {
  checkDisposition = (toBeChechedDisposition: string): boolean => {
    let { disposition: current } = this.props

    while (current != null && toBeChechedDisposition != current) {
      current = immediatePast[current]
    }

    return toBeChechedDisposition == current
  }

  render() {
    const {disposition, t} = this.props
    return <div className='quex-simulation-disposition'>
      <h4>{t('Disposition')}</h4>
      <ul className='disposition radio-no-pointer'>
        <li>
          <div className='row'>
            <div className='col s3'>
              <p>{t('Uncontacted')}</p>
            </div>
            <div className='col s9'>
              <ul>
                <li className={classNames({'active': disposition == 'registered'})}>
                  <input
                    id='registered'
                    type='radio'
                    name='registered'
                    value='default'
                    readOnly
                    checked={this.checkDisposition('registered')}
                    className='with-gap'
                  />
                  <label htmlFor='registered'>{t('Registered')}</label>
                </li>
                <li className={classNames({'active': disposition == 'queued'})}>
                  <input
                    id='queued'
                    type='radio'
                    name='queued'
                    value='default'
                    readOnly
                    checked={this.checkDisposition('queued')}
                    className='with-gap'
                  />
                  <label htmlFor='queued'>{t('Queued')}</label>
                  <ul>
                    <li className={classNames({'active': disposition == 'failed'})}>
                      <input
                        id='failed'
                        type='radio'
                        name='failed'
                        value='default'
                        readOnly
                        checked={this.checkDisposition('failed')}
                        className='with-gap'
                      />
                      <label htmlFor='failed'>{t('Failed')}</label>
                    </li>
                  </ul>
                </li>
              </ul>
            </div>
          </div>
        </li>
        <li>
          <div className='row'>
            <div className='col s3'>
              <p>{t('Contacted')}</p>
            </div>
            <div className='col s9'>
              <ul>
                <li className={classNames({'active': disposition == 'contacted'})}>
                  <input
                    id='contacted'
                    type='radio'
                    name='contacted'
                    value='default'
                    readOnly
                    checked={this.checkDisposition('contacted')}
                    className='with-gap'
                  />
                  <label htmlFor='contacted'>{t('Contacted')}</label>
                  <ul>
                    <li className={classNames({'active': disposition == 'unresponsive'})}>
                      <input
                        id='unresponsive'
                        type='radio'
                        name='unresponsive'
                        value='default'
                        readOnly
                        checked={this.checkDisposition('unresponsive')}
                        className='with-gap'
                      />
                      <label htmlFor='unresponsive'>{t('Unresponsive')}</label>
                    </li>
                  </ul>
                </li>
              </ul>
            </div>
          </div>
        </li>
        <li>
          <div className='row'>
            <div className='col s3'>
              <p>{t('Responsive')}</p>
            </div>
            <div className='col s9'>
              <ul className='last'>
                <li className={classNames({'active': disposition == 'started'})}>
                  <input
                    id='started'
                    type='radio'
                    name='started'
                    value='default'
                    readOnly
                    checked={this.checkDisposition('started')}
                    className='with-gap'
                  />
                  <label htmlFor='started'>{t('Started')}</label>
                  <ul>
                    <li className={classNames({'active': disposition == 'refused'})}>
                      <input
                        id='refused'
                        type='radio'
                        name='refused'
                        value='default'
                        readOnly
                        checked={this.checkDisposition('refused')}
                        className='with-gap'
                      />
                      <label htmlFor='refused'>{t('Refused')}</label>
                    </li>
                    <li className={classNames({'active': disposition == 'ineligible'})}>
                      <input
                        id='ineligible'
                        type='radio'
                        name='ineligible'
                        value='default'
                        readOnly
                        checked={this.checkDisposition('ineligible')}
                        className='with-gap'
                      />
                      <label htmlFor='ineligible'>{t('Ineligible')}</label>
                    </li>
                    <li className={classNames({'active': disposition == 'rejected'})}>
                      <input
                        id='rejected'
                        type='radio'
                        name='rejected'
                        value='default'
                        readOnly
                        checked={this.checkDisposition('rejected')}
                        className='with-gap'
                      />
                      <label htmlFor='rejected'>{t('Rejected')}</label>
                    </li>
                    <li className={classNames({'active': disposition == 'breakoff'})}>
                      <input
                        id='breakoff'
                        type='radio'
                        name='breakoff'
                        value='default'
                        readOnly
                        checked={this.checkDisposition('breakoff')}
                        className='with-gap'
                      />
                      <label htmlFor='breakoff'>{t('Breakoff')}</label>
                    </li>
                  </ul>
                </li>
                <li className={classNames({'active': disposition == 'interim partial'})}>
                  <input
                    id='interim partial'
                    type='radio'
                    name='interim partial'
                    value='default'
                    readOnly
                    checked={this.checkDisposition('interim partial')}
                    className='with-gap'
                  />
                  <label htmlFor='partial'>{t('Interim Partial')}</label>
                  <ul>
                    <li className={classNames({'active': disposition == 'partial'})}>
                      <input
                        id='partial'
                        type='radio'
                        name='partial'
                        value='default'
                        readOnly
                        checked={this.checkDisposition('partial')}
                        className='with-gap'
                      />
                      <label htmlFor='partial'>{t('Partial')}</label>
                    </li>
                  </ul>
                </li>
                <li className={classNames({'active': disposition == 'completed'})}>
                  <input
                    id='completed'
                    type='radio'
                    name='completed'
                    value='default'
                    readOnly
                    checked={this.checkDisposition('completed')}
                    className='with-gap'
                  />
                  <label htmlFor='completed'>{t('Completed')}</label>
                </li>
              </ul>
            </div>
          </div>
        </li>
      </ul>
    </div>
  }
}

export default translate()(DispositionChart)
