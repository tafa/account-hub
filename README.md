
## Authkeys

An **authkey** is a JSON object, e.g.

<pre>
{"type": "hmac-sha256", "key": "...base64...", "url": "https://example.com", "token": "EWyYz92V"}
</pre>

hmac-sha256 is the only supported type so far.



## API Usage

API requests are POST requests to https://example.com/api/v0.1/(function name).js

{Request,response} body encoding: application/json

The following HTTP headers are required:

* <code>X-Authkey-Token: ...token...</code>
* <code>X-Authkey-Signature: ...base64...</code>

In addition to the parameters mentioned below, each request must include:

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
        amount: "1.23 BTC"
        title: "..."
        toAccountToken: ""
    }
    {
        invoiceToken: ""
    }

check-invoice-status
    {
        invoiceToken: 
        [msToWaitForPayment: 15000]
    }
    {
        paid: true or false
    }
</pre>

### Accounts and Authkeys

<pre>
create-account
    {}
    {
        accountToken: ""
        # This authkey has all permissions for the above account:
        authkey: {...}
    }

create-authkey
    {
        accountToken: ""
    }
    {
        # a new authkey with no permissions
        authkey:
    }

change-authkey-permissions
    {
        authkeyToken: 
        "add": [
            # Example:
            [accountToken, "post-invoice"],
            [accountToken, "check-invoice-status"]
        ]
        "remove": [
            # Example:
            [accountToken, "transfer"], # Revoke "transfer" for (this authkey, this account)
            [null,         "transfer"], # Revoke "transfer" for (this authkey, all accounts)
        ]
    }
    {}
</pre>


### Transfer

<pre>
TODO
</pre>
