import React, { PureComponent } from 'react'

import { Link } from 'react-router'
import * as routes from '../../routes'

import { Card, UntitledIfEmpty } from '../ui'
import RespondentsChart from '../respondents/RespondentsChart'
import SurveyStatus from '../surveys/SurveyStatus'

class SurveyCard extends PureComponent<any> {
  props: {
    t: Function,
    respondentsStats: Object,
    survey: Survey,
    onDelete: (survey: Survey) => void,
    readOnly: boolean
  };

  render() {
    const { survey, respondentsStats, onDelete, readOnly, t } = this.props

    var deleteButton = null
    if (survey.state != 'running') {
      const onDeleteClick = (e) => {
        e.preventDefault()
        onDelete(survey)
      }

      deleteButton = readOnly ? null
        : <span onClick={onDeleteClick} className='right card-hover grey-text'>
          <i className='material-icons'>delete</i>
        </span>
    }

    let cumulativePercentages = respondentsStats ? (respondentsStats['cumulativePercentages'] || {}) : {}
    let completionPercentage = respondentsStats ? (respondentsStats['completionPercentage'] || 0) : 0

    let description = <div className='grey-text card-description'>
      {survey.description}
    </div>

    return (
      <div className='col s12 m6 l4'>
        <Link className='survey-card' to={routes.showOrEditSurvey(survey)}>
          <Card>
            <div className='card-content'>
              <div className='grey-text'>
                {t('{{percentage}}% of target completed', {percentage: String(Math.round(completionPercentage))})}
              </div>
              <div className='card-chart'>
                <RespondentsChart cumulativePercentages={cumulativePercentages} />
              </div>
              <div className='card-status'>
                <div className='card-title truncate' title={survey.name}>
                  <UntitledIfEmpty text={survey.name} emptyText={t('Untitled survey')} />
                  {deleteButton}
                </div>
                {description}
                <SurveyStatus survey={survey} short />
              </div>
            </div>
          </Card>
        </Link>
      </div>
    )
  }
}

export default SurveyCard