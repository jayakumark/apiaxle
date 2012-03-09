#!/usr/bin/env coffee

# extends Date
_ = require "underscore"

express      = require "express"
sys          = require "sys"
fs           = require "fs"
redis        = require "redis"

{ Application } = require "apiaxle.base"
{ StdoutLogger  } = require "./lib/stderrlogger"
{ NotFoundError } = require "./lib/error"

class exports.ApiaxleApi extends Application
  @controllersPath = "#{ __dirname }/app/controller"

  configureGeneral: ( app ) ->
    app.use express.methodOverride()
    app.use express.bodyParser()

    app.enable "jsonp callback"

    super

if not module.parent
  # taking a port from the commandline makes it much easier to cluster
  # the app
  port = ( process.argv[2] or 3000 )
  host = "127.0.0.1"

  api = new exports.ApiaxleApi( )

  api.redisConnect ( ) ->
    api.run host, port, ( ) ->
      api.configureModels()
      api.configureControllers()
      api.configureMiddleware()

      console.log "Express server listening on port #{port}"