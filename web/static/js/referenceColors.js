// @flow
import range from 'lodash/range'

const referenceColors = [
  '#673ab7', '#3f51b5', '#2196f35', '#03a9f4',
  '#00bcd4', '#009688', '#4caf50', '#8bc34a',
  '#cddc39', '#ffeb3b', '#ffc107', '#ff9800',
  '#ff5722', '#f44336', '#e91e63', '#9c27b0'
]

const singleColor = '#4faf55'

export function referenceColorClasses(totalNeeded: number) {
  let nextColorIncrement = referenceColors.length / totalNeeded
  return range(0, totalNeeded).map((i) => {
    return 'referenceColor' + (i * nextColorIncrement)
  })
}

export function referenceColorsFor(totalNeeded: number) {
  if (totalNeeded == 1) {
    return [singleColor]
  }
  let nextColorIncrement = referenceColors.length / totalNeeded
  return range(0, totalNeeded).map((i) => {
    return referenceColors[i * nextColorIncrement]
  })
}
