import iso6393 from 'iso-639-3'
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

export const translateLangCode = (code) => {
  const language = iso6393.find((lang) => lang.iso6391 == code || lang.iso6393 == code)
  return language.name
}

export const arrayDiff = (base, compare) => {
  return base.filter(function(i) { return compare.indexOf(i) < 0 })
}
