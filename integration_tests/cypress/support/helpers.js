export function validRespondentStateDisposition(respondent) {
  const validStateDisposition = [
    { disposition: 'contacted', state: 'active' },
    { disposition: 'interim partial', state: 'active' },
    { disposition: 'queued', state: 'active' },
    { disposition: 'started', state: 'active' },
    { disposition: 'breakoff', state: 'cancelled' },
    { disposition: 'contacted', state: 'cancelled' },
    { disposition: 'failed', state: 'cancelled' },
    { disposition: 'ineligible', state: 'cancelled' },
    { disposition: 'interim partial', state: 'cancelled' },
    { disposition: 'queued', state: 'cancelled' },
    { disposition: 'refused', state: 'cancelled' },
    { disposition: 'started', state: 'cancelled' },
    { disposition: 'unresponsive', state: 'cancelled' },
    { disposition: 'completed', state: 'completed' },
    { disposition: 'ineligible', state: 'completed' },
    { disposition: 'partial', state: 'completed' },
    { disposition: 'refused', state: 'completed' },
    { disposition: 'rejected', state: 'completed' },
    { disposition: 'breakoff', state: 'failed' },
    { disposition: 'failed', state: 'failed' },
    { disposition: 'partial', state: 'failed' },
    { disposition: 'unresponsive', state: 'failed' },
    { disposition: 'registered', state: 'pending' },
    { disposition: 'rejected', state: 'rejected' },
  ]
  return !!validStateDisposition.find(x => x.disposition == respondent.disposition && x.state == respondent.state)
}
