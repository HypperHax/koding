teamsHelpers = require '../helpers/teamshelpers.js'
helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
virtualMachinesUrl = "#{helpers.getUrl(yes)}/Home/Stacks/virtual-machines"
async = require 'async'


module.exports =

  before: (browser, done) ->

    ###
    * we are creating users list here to send invitation and join to team
    * so we will be able to run our test for different kind of member role
    ###
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'

    users =
      targetUser1

    queue = [
      (next) ->
        teamsHelpers.inviteAndJoinWithUsers browser, [ users ], (result) ->
          next null, result
      (next) ->
        teamsHelpers.buildStack browser, (res) ->
          next null, res
    ]

    async.series queue, (err, result) ->
      done()  unless err
