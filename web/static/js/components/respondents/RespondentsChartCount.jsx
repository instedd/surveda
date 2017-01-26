export const cumulativeCount = (completedByDate, targetValue) => {
  const cumulativeCount = []
  for (let i = 0; i < completedByDate.length; i++) {
    let d = completedByDate[i].date
    let current = {}
    current['date'] = d
    current['count'] = cumulativeCountFor(d, completedByDate) / targetValue * 100
    cumulativeCount.push(current)
  }
  return cumulativeCount
}

export const cumulativeCountFor = (d, completedByDate) => {
  const dateMilliseconds = Date.parse(d)
  return completedByDate.reduce((pre, cur) => {
    return Date.parse(cur.date) <= dateMilliseconds && cur.date >= pre.date
    ? cur
    : pre
  }, {date: '', count: 0}).count
}

export const respondentsReachedPercentage = (completedByDate, targetValue) => {
  const reached = completedByDate.length == 0 ? 0 : cumulativeCountFor(completedByDate[completedByDate.length - 1].date, completedByDate)
  const percent = Math.round(reached * 100 / targetValue)
  return percent >= 100 ? 100 : percent
}
