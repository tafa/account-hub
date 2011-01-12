
exports.overview = {
  req_url: 'https://mtgox.com/code/(function_name).php'
  req_method: 'POST'
  post_body_encoding: 'application/x-www-form-urlencoded'
  req_authentication_type: 1
  supported_functions: [
    'send-btc', 'my-balance',
    'place-order', 'my-open-orders', 'cancel-order'
  ]
}


exports['place-order'] = {
  req: (x) ->
    if x.trade_cur == "USD" and x.for_cur == "BTC"
      ['buyBTC', {
        amount: TODO
        price: TODO
      }]
    else if x.trade_cur == "BTC" and x.for_cur == "USD"
      ['sellBTC', {
        amount: TODO
        price: TODO
      }]
    else
      throw new Error "Unsupported currency pair"
}

