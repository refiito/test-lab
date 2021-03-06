LinkedInStrategy = require('passport-linkedin-oauth2').Strategy
{ User }         = require '../models'

{ linkedIn } = require '../../config/strategies'

module.exports = new LinkedInStrategy linkedIn, (accessToken, refreshToken, profile, done) ->
  profile = profile._json
  fields  =
    email: profile.emailAddress
    avatar: profile.pictureUrl
    url: profile.publicProfileUrl
    name: "#{profile.firstName} #{profile.lastName}"
    authType: 'linkedin'

  User.findOrCreate fields, done
