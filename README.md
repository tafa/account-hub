
## Overview

This is an exploratory project. It will eventually become suitable for production use.

This is project permissively-licensed [FOS](http://en.wikipedia.org/wiki/Free_and_open_source_software)&mdash;[SAAS](http://en.wikipedia.org/wiki/Software_as_a_service).

It implements the usual aspects of a Bitcoin account service:

* Users can create accounts
* Intra-hub transfers can happen in less than a second
* Normal Bitcoin transfers can be [made to] or [received from] any Bitcoin address

<!--
* You can convert BTC to/from other currencies via API requests to a forex service
-->

Additionally, it supplements the Bitcoin network in two ways:

### Rapid Invoice Broadcasting

* The AHs maintain a side network for propagating tiny messages rapidly among the AHs
* Each message is signed by the AH that sent it
* The only message sent on that network so far:
    * <code>NEW-INVOICE(invoiceToken, timestamp, amount, extra info)</code>
    * *(see below for details)*

*"What about near-field wireless or QR-code-scanning or other means of sending the invoice directly to the customer?"*, you might ask. Sure, use them if possible. Invoice-broadcasting is simply one solution that works now on any smartphone and any POS hardware with an internet connection.

### Reputation-backed Inter-Hub Transfers

* When AH X makes a transfer to AH Y,
    * X makes an ordinary Bitcoin transfer to one of Y's Bitcoin addresses
    * X also sends a message directly to Y (via Y's HTTPS API):
        * <code>REPUTATION-BACKED-TRANSFER(Bitcoin transfer data, X's public key)</code>
        * The message is signed by X's private key
        * The message is also signed by the private key ("K") which owns the Bitcoins
        * You could think of the message as "meaning" "I, X, am the only entity with control over K and I promise not to do anything in conflict with this transfer (like double-spending)."
        * Typically, this will lower the probability of a multispend attempt from Y's POV, thus lowering the cost of offering Multispend Insurance.


## Things a specific AH ("Y") might want to offer its customers

### Multispend Insurance

* For a small cut, Y could eat the multi-spend risk of a specific incoming <code>0/unconfirmed</code> transfer
* <code>REPUTATION-BACKED-TRANSFER</code> messages could reduce that cut

### Instant Forex Rates, Delayed Transfer

See the cafe example.

## Cafe Example

The scene:

* You, the customer, have an account on AH X and a smartphone with AH-mobile with an authkey with {pay-invoice} permission for your account.
* There's a cafe with POS software ("POS") which has authkeys with  <code>{post-invoice,check-invoice-status}</code> permissions for accounts on AHs Y and Z

The transaction:

* You open the AH-mobile app
* Cashier says "That'll be $3.42" (CAD)
* You say "Bitcoin"
* The cashier presses the Bitcoin button
* POS calls <code>/get-exchange-quote</code> on Y and Z and chooses the one with the best rate ("10.75 BTC")
* In this example, that's Y
* POS calls <code>/post-invoice</code> on Y
* Y broadcasts the invoice, requesting "10.75 BTC" from anyone
* X gets the invoice and notifies your phone, e.g. via HTTPS long-polling *(TODO: that API request)*
* *(note: you'll only see e.g. still-pending invoices posted less than 15 seconds ago in a 5-block radius of your phone)*
* *(this could be filtered further e.g. by a random 3-digit code which the cashier would read to you)*
* After looking at the details, you press "Pay"
* Your app calls <code>/pay-invoice</code> on X
* X pays Y "10.75 BTC" (see *Reputation-backed Inter-Hub Transfers* above)
* Y, providing multi-spend insurance, tells POS that the transaction was a success

Aftermath:

* Y converts among its currency reserves whenever and however it sees fit
* Y adds $3.42 CAD to the cafe's account within a few hours of the transaction

<!--
    and nativeAmount:"3.42 CAD"
        * nativeAmount is just a label
-->

## Installing / Using

If you're not a developer, you probably should wait. [Freedom box](http://wiki.debian.org/FreedomBox) attempts are on their way ([I'll be releasing an exploratory one later this month](https://github.com/tafa)), and they will make it amazingly easy to install and maintain [FOS](http://en.wikipedia.org/wiki/Free_and_open_source_software)&mdash;[SAAS](http://en.wikipedia.org/wiki/Software_as_a_service) like this.

## Developing

Prereqs: [NodeJS](http://nodejs.org/) (>= 0.3.4) and [npm](https://github.com/isaacs/npm)

<pre>
cd account-hub
npm link
&lt;not-yet-released-tool&gt; dev
</pre>

# HTTPS API

## Authkeys

An **authkey** is a JSON object, e.g.

<pre>
{"type": "hmac-sha256", "key": "...base64...", "url": "https://example.com", "token": "EWyYz92V"}
</pre>

## API Authentication


To authenticate an HTTPS request with one or more authkeys, add these headers:

* <code>X-Authkey-Tokens: ...JSON(list of tokens)...</code>
* <code>X-Signature-&lt;token&gt;: ...base64...</code> (for each authkey)

For HMAC-256 authkeys:

* Signature: <code>hmac('sha256', key).update(request body).digest('base64')</code>

For private-key authkeys:

* Signature: (TODO)

Required authentication:

* <code>create-account</code> does not require authentication
* <code>reputation-backed-transfer-message</code> requires private-key authentication from both X's key and K (see example in overview)
* All others require authentication from some authkey (typically HMAC-256)

## API Usage

API requests are POST requests to https://example.com/api/v0.1/(function name).js

{Request,response} body encoding: application/json

In addition to the properties mentioned below, each request must include:

* <code>requestToken: "...any string you'll never send again (e.g. a [UUID](http://en.wikipedia.org/wiki/UUID))..."</code>

(any requests that reuse an (authkey token, requestToken) pair will be rejected)

If there's an error, the HTTP response code will be 5xx and the body JSON will include these properties:
<pre>
{
    "error": {
        "message": "..."
    }
}
</pre>

## API Functions

### Invoices

<pre>
post-invoice
    {
        amount: "3.42 CAD"
        to_account_token: ""
        quote_tokens: [...] # see /get-exchange-quote
        extra_info: {
            # each field is optional:
            
            title: "XL Coffee, 4 timbits"
            
            lat: ""
            lng: ""
        }
    }
    {
        invoice_oken: ""
    }

check-invoice-status
    {
        invoice_token: ""
        wait_for_result: "15000 ms"
    }
    {
        status: 'pending' or 'succeeded' or 'failed'
    }
</pre>

### Accounts and Authkeys

<pre>
create-account
    {}
    {
        account_oken: ""
        # This authkey has all permissions for the above account:
        authkey: {...}
    }

create-authkey
    {
        account_token: ""
    }
    {
        # a new authkey with no permissions
        authkey: {...}
    }

change-authkey-permissions
    {
        authkey_token: 
        "add": [
            # Example:
            [account_token, "post-invoice"],
            [account_token, "check-invoice-status"]
        ]
        "remove": [
            # Example:
            [accountToken,  "transfer"],  # Revoke "transfer" for that (authkey, account)
            ["all",         "transfer"], # Revoke "transfer" for (that authkey, all accounts)
            [accountToken2, "all"]       # Revoke all permissions for that (authkey, account)
        ]
    }
    {}
</pre>


### Transfers

<pre>
pay-invoice
    {
        from_account_token: ""
        invoice_token: ""
    }
    {}

send-bitcoins
    {
        from_account_token: ""
        to_bitcoin_address: ""
        amount: "17.58"
    }
    {}

new-bitcoin-address
    {}
    {
        address: ""
    }
</pre>

<pre>
reputation-backed-transfer-message
    {
        bitcoin_transfer: "...base64 data..."
        hub_public_key: {...}
    }
    {}
</pre>

## Currency Exchange

<pre>
get-exchange-quote
    {
        from: "BTC"
        to_amount: "3.42 USD"
        valid_for: "10.5 seconds"
    }
    {
        from_amount: "10.75 BTC"
        quote_token: ""
    }
</pre>


# Side Network

## Temporary System

This system does not scale, but it'll be fine for testing a double-digit set of AHs.

It will be replaced by something better.

<pre>
A TCP connection is maintained between each pair of account hubs.

TODO full writeup
</pre>

## Message Encoding

<pre>
TODO
</pre>