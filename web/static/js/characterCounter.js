import gsm from 'gsm'

export const characterLimit = (text) => {
  if (gsm(text).char_set == 'Unicode') {
    return 70
  } else {
    // GSM 03.38
    return 160
  }
}

export const characterCount = (text) => {
  const parts = gsm(text)
  const limit = characterLimit(text)
  if (parts.sms_count == 0) {
    return 0
  } else {
    if (parts.sms_count == 1) {
      return limit - parts.chars_left
    } else {
      // max limit according to gsm library for each character set when sms_count > 0
      const maxLimitWhenMultipart = (limit == 160) ? 153 : 67
      return parts.sms_count * maxLimitWhenMultipart - parts.chars_left
    }
  }
}

export const limitExceeded = (text) => {
  return gsm(text).sms_count > 1
}
