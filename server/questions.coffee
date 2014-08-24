_ = require 'lodash'

arrToObj         = require '../lib/arr-to-obj'
requireDir       = require '../lib/require-dir'
validateQuestion = require '../lib/validate-question'

# All questions that we have
exports.list = []

exports.clear = =>
  @list = []

exports.load = (dir) =>
  @list = requireDir(dir).filter validateQuestion

exports.getRandomQuestions = (type, nr = 1) =>
  throw new Error("No question type defined") unless type
  _(@list).filter({ type })
          .shuffle()
          .first(nr)
          .value()

exports.buildQuestionList = (questionCountByType) =>
  _.transform questionCountByType, (obj, val, key) =>
    obj[key] = arrToObj @getRandomQuestions key, val
