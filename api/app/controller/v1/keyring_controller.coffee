_ = require "lodash"

{ ApiaxleController, ListController } = require "../controller"
{ AlreadyExists } = require "../../../lib/error"

class exports.CreateKeyring extends ApiaxleController
  @verb = "post"

  desc: -> "Provision a new KEYRING."

  docs: ->
    """
    ### JSON fields supported

    #{ @app.model( 'keyringFactory' ).getValidationDocs() }

    ### Returns

    * The inserted structure (including the new timestamp fields).
    """

  middleware: -> [ @mwValidateQueryParams(),
                   @mwKeyringDetails( ) ]

  path: -> "/v1/keyring/:keyring"

  execute: ( req, res, next ) ->
    # error if it exists
    if req.keyring?
      return next new AlreadyExists "'#{ req.keyring.id }' already exists."

    model = @app.model "keyringFactory"
    model.create req.params.keyring, req.body, ( err, newObj ) =>
      return next err if err

      @json res, newObj.data

class exports.ViewKeyring extends ApiaxleController
  @verb = "get"

  desc: -> "Get the definition for an KEYRING."

  docs: ->
    """
    ### Returns

    * The KEYRING structure (including the timestamp fields).
    """

  middleware: -> [ @mwValidateQueryParams(),
                   @mwKeyringDetails( valid_keyring_required=true ) ]

  path: -> "/v1/keyring/:keyring"

  execute: ( req, res, next ) ->
    @json res, req.keyring.data

class exports.DeleteKeyring extends ApiaxleController
  @verb = "delete"

  desc: -> "Delete an KEYRING."

  docs: ->
    """
    ### Returns

    * `true` on success.
    """

  middleware: -> [ @mwValidateQueryParams(),
                   @mwKeyringDetails( valid_keyring_required=true ) ]

  path: -> "/v1/keyring/:keyring"

  execute: ( req, res, next ) ->
    model = @app.model "keyringFactory"

    model.del req.params.keyring, ( err, newKeyring ) =>
      return next err if err

      @json res, true

class exports.ModifyKeyring extends ApiaxleController
  @verb = "put"

  desc: -> "Update an KEYRING."

  docs: ->
    """Will merge fields you pass in.

    ### JSON fields supported

    #{ @app.model( 'keyringFactory' ).getValidationDocs() }

    ### Returns

    * The merged structure (including the timestamp fields).
    """

  middleware: -> [
    @mwContentTypeRequired( ),
    @mwKeyringDetails( valid_keyring_required=true ),
    @mwValidateQueryParams()
  ]

  path: -> "/v1/keyring/:keyring"

  execute: ( req, res, next ) ->
    req.keyring.update req.body, ( err, new_keyring, old_keyring ) =>
      return next err if err
      return @json res,
        new: new_keyring
        old: old_keyring

class exports.ListKeyringKeys extends ListController
  @verb = "get"

  path: -> "/v1/keyring/:keyring/keys"

  desc: -> "List keys belonging to an KEYRING."

  queryParams: ->
    params =
      type: "object"
      additionalProperties: false
      properties:
        from:
          type: "integer"
          default: 0
          docs: "The index of the first key you want to
                 see. Starts at zero."
        to:
          type: "integer"
          default: 10
          docs: "The index of the last key you want to see. Starts at
                 zero."
        resolve:
          type: "boolean"
          default: false
          docs: "If set to `true` then the details concerning the
                 listed keys will also be printed. Be aware that this
                 will come with a minor performace hit."

  docs: ->
    """
    ### Supported query params

    #{ @queryParamDocs() }

    ### Returns

    * Without `resolve` the result will be an array with one key per
      entry.
    * If `resolve` is passed then results will be an object with the
      key name as the key and the details as the value.
    """

  modelName: -> "keyFactory"

  middleware: -> [ @mwValidateQueryParams(),
                   @mwKeyringDetails( @app ) ]

class exports.UnlinkKeyToKeyring extends ApiaxleController
  @verb = "put"

  desc: -> "Disassociate a key with a KEYRING."

  docs: ->
    """
    The key will still exist and its details won't be affected.

    ### Returns

    * The unlinked key details.
    """

  middleware: -> [ @mwKeyringDetails( valid_keyring_required=true ),
                   @mwKeyDetails( valid_key_required=true ),
                   @mwValidateQueryParams() ]

  path: -> "/v1/keyring/:keyring/unlinkkey/:key"

  execute: ( req, res, next ) ->
    req.keyring.unlinkKeyById req.key.id, ( err ) =>
      return next err if err

      @json res, req.key.data

class exports.LinkKeyToKeyring extends ApiaxleController
  @verb = "put"

  desc: -> "Associate a key with a KEYRING."

  docs: ->
    """
    The key must already exist and will not be modified by this
    operation.

    ### Returns

    * The linked key details.
    """

  middleware: -> [ @mwKeyringDetails( valid_keyring_required=true ),
                   @mwKeyDetails( valid_key_required=true ),
                   @mwValidateQueryParams() ]

  path: -> "/v1/keyring/:keyring/linkkey/:key"

  execute: ( req, res, next ) ->
    req.keyring.linkKey req.key.id, ( err ) =>
      return next err if err

      @json res, req.key.data
