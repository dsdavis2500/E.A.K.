module.exports = (fn, arr, into = arr) ->
  good-index = 0
  for item, i in arr
    unless fn item
      into[good-index] = item
      good-index++

  into.length = good-index
  into
