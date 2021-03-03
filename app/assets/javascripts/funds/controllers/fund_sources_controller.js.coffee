app.controller 'FundSourcesController', ['$scope', '$gon', 'fundSourceService', ($scope, $gon, fundSourceService) ->

  $scope.banks = $gon.banks
  $scope.currency = currency = $scope.ngDialogData.currency

  $scope.fund_sources = ->
    fundSourceService.filterBy currency:currency

  $scope.defaultFundSource = ->
    fundSourceService.defaultFundSource currency:currency

  $scope.add = ->
    uid   = $scope.uid.trim()   if angular.isString($scope.uid)
    extra = $scope.extra.trim() if angular.isString($scope.extra)
    bank_code = $scope.bank_code.trim() if $scope.currency == 'inr' && angular.isString($scope.bank_code)
    destination_tag = $scope.destination_tag if $scope.currency == 'xrp' && angular.isNumber($scope.destination_tag)
    destination_tag = $scope.destination_tag if $scope.currency == 'xmr' && angular.isString($scope.destination_tag)

    return if not uid
    return if not extra
    return if $scope.currency == 'inr' && not bank_code
    return if $scope.currency == 'xrp' && not destination_tag && destination_tag != 0
    return if $scope.currency == 'xmr' && not destination_tag && destination_tag.length <= 0

    data = uid: uid, extra: extra, currency: currency, destination_tag: destination_tag
    fundSourceService.create data, ->
      $scope.uid = ""
      $scope.extra = "" if currency isnt $gon.fiat_currency
      $scope.destination_tag = ""

  $scope.remove = (fund_source) ->
    fundSourceService.remove fund_source

  $scope.makeDefault = (fund_source) ->
    fundSourceService.update fund_source

]
