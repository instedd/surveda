export const formatTimezone = (tz) => {
  const split = (tz || 'UTC').replace('_', ' ').split('/')
  switch (split.length) {
    case 2:
      return `${split[0]} - ${split[1]}`
    case 3:
      return `${split[0]} - ${split[2]}, ${split[1]}`
    default:
      return split[0]
  }
}
