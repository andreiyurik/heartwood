export function debounce(fn, delay = 1000) {
  let timeoutId = null

  const debounced = (...args) => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => fn(...args), delay)
  }
  debounced.cancel = () => clearTimeout(timeoutId)

  return debounced
}
