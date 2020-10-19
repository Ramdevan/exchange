@FlashMessageUI = flight.component ->

  @info = (event, data) ->
    toastr.success(data.msg)

  @notice = (event, data) ->
    toastr.info(data.msg)

  @alert = (event, data) ->
    toastr.error(data.msg)

  @error = (event, data) ->
    toastr.error(data.msg)

  @after 'initialize', ->
    @on document, 'flash:info', @info
    @on document, 'flash:notice', @notice
    @on document, 'flash:alert', @alert
    @on document, 'flash:error', @error
