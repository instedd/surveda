export const toggleColourScheme = (scheme) => {
  if (scheme == 'better_data_for_health') {
    document.documentElement.style.setProperty('--header-color', 'blue')
  } else {
    document.documentElement.style.setProperty('--header-color', '#424242')
  }
}
