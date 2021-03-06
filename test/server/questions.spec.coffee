proxyquire = require 'proxyquire'
sinon      = require 'sinon'
path       = require 'path'
_          = require 'lodash'
assert     = require 'assert'

questions = proxyquire '../../server/questions',
  'require-dir-sync': -> requireStub arguments...
  '../lib/validate-question': -> validateQStub arguments...

requireStub   = null
validateQStub = null
describe 'questions', ->
  describe '#clear', ->
    it 'should unset the list', ->
      questions.list = 'asd'
      questions.clear()
      questions.list.should.eql []

  describe '#load', ->
    beforeEach ->
      requireStub   = sinon.stub()
      validateQStub = sinon.stub()

    afterEach questions.clear

    it 'should require all files from input directory', ->
      requireStub.returns []
      questions.load 'dir'
      requireStub.calledWith('dir').should.be.ok

    it 'should not add questions that do not pass the validator', ->
      question = [ {'test'} ]
      requireStub.returns question
      validateQStub.returns false
      questions.load 'dir'
      questions.list.should.be.eql {}

    it 'should add questions that do pass the validator', ->
      question = [ {'test'} ]
      requireStub.returns question
      validateQStub.returns true
      questions.load 'dir'
      questions.list[0].test.should.eql 'test'

    it 'should add fileNames to question objects', ->
      question = { asd: { 'test' } }
      requireStub.returns question
      validateQStub.returns true
      questions.load 'dir'
      questions.list[0].fileName.should.eql 'asd'

  describe '#getRandomQuestions', ->
    beforeEach ->
      type = "test"
      questions.list = [
        { type, "nr": 1 }
        { type, "nr": 2 }
        { type, "nr": 3 }
      ]

    afterEach questions.clear

    it 'should throw if no type is defined', ->
      (->
        questions.getRandomQuestions null
      ).should.throw "No question type defined"

    it 'should return one question by default', ->
      res = questions.getRandomQuestions "test"
      res.length.should.be.eql 1

    it 'should return the right number of questions', ->
      res = questions.getRandomQuestions "test", 3
      res.length.should.be.eql 3

    it 'should return an empty array if the type is not defined', ->
      res = questions.getRandomQuestions "does-not-exist", 12
      res.length.should.be.eql 0

  describe '#getRandomQuestionsCombined', ->
    beforeEach ->
      type = "test"
      questions.list = [
        { type, "nr": 1 }
        { type, "nr": 2 }
        { type, "nr": 3 }
      ]

    afterEach questions.clear
    it 'should call getRandomQuestions for each key', sinon.test ->
      @spy questions, 'getRandomQuestions'
      questions.getRandomQuestionsCombined 'test': 2
      questions.getRandomQuestions.calledWith('test', 2).should.be.ok

    it 'should return an array', ->
      res = questions.getRandomQuestionsCombined test: 2
      res.should.be.instanceof Array

    it 'should return an array with one level', ->
      res = questions.getRandomQuestionsCombined test: 3
      flat = _.flatten res
      res[0].should.eql flat[0]

    it 'should return random questions', ->
      res = questions.getRandomQuestionsCombined test: 1
      res[0].type.should.eql 'test'

  describe '#findByFilename', ->
    it 'should exist', ->
      questions.findByFilename.should.be.ok

    it 'should find model by its fileName', ->
      questions.list = [ fileName: 'test' ]
      questions.findByFilename('test').should.be.ok

    it 'should return null if does not exist', ->
      questions.list = [ fileName: 'test1' ]
      res = questions.findByFilename 'test'
      assert res is undefined

  describe '#findAndValidate', ->
    it 'should return error if model is not found', (done) ->
      sinon.stub(questions, 'findByFilename').returns null
      questions.findAndValidate 'asd', 'content', (err, result) ->
        err.should.be.ok
        questions.findByFilename.restore()
        done result

    it 'should return true if question has no validate method', (done) ->
      sinon.stub(questions, 'findByFilename').returns {}
      questions.findAndValidate 'asd', 'content', (err, result) ->
        result.should.be.ok
        questions.findByFilename.restore()
        done err

    it 'should return error if validate fn throws', (done) ->
      validate = -> throw new Error 'WHAT IS THIS'
      sinon.stub(questions, 'findByFilename').returns { validate }
      questions.findAndValidate 'asd', 'content', (err, result) ->
        err.should.be.ok
        questions.findByFilename.restore()
        done result

    it 'should return value according to validate callback', (done) ->
      validate = (data, callback) -> callback null, data
      sinon.stub(questions, 'findByFilename').returns { validate }
      questions.findAndValidate 'asd', 'content', (err, result) ->
        result.should.be.eql 'content'
        questions.findByFilename.restore()
        done err
