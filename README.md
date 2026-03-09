# Riskinator©, brought to you by Baby Sloth Softworks LLC
A simple API to help you mitigate risk

# HOW MAKE GO?!
## Install Rails 8 and All The Things™
_NOTE: This assumes setup using homebrew_

1.) Install ruby dependencies: `brew install openssl@3 LibYaml gmp rust`

2.) Install `rvm`, `rbenv`, or something like `mise` Ruby version manager: `brew install mise`

3.) install ruby 3.4.2: `mise install ruby@3.4.2`

4.) install rails: `gem install rails`

- Ensure it actually runs when you type `rails s`
- If it doesn't run, fix it
- Once it's running, hit it with a POST request like it says below
- Marvel at the wonders of Ruby on Rails

# HOW DO RISK ASSESSMENT?!
- You can send a json blob via POST request to `/riskit` that looks like this:

```
{
  "commuterId": "COM-123",
  "actions": [
    {
      "timestamp": "2022-01-01 10:05:11",
      "action": "walked on sidewalk",
      "unit": "mile",
      "quantity": 0.4
    },
    {
      "timestamp": "2022-01-01 10:30:09",
      "action": "rode a shark",
      "unit": "minute",
      "quantity": 3
    }
  ]
}
```
## HOW PARAM?!
- Each riskinator request hash should have the following keys:
`"commuterId"` - a unique string identifier for the commuter in question
`"actions"` - an array of `action_items` hashes
** IMPORTANT: each riskinator request hash should include `actions` only for the same given day - different days should be handled in different requests **

- Each `action_item` hash should have the following:
`"timestamp"` - standard DateTime object
`"action"` - A string with the action to be assessed
`"unit"` - one of the following values in string form: mile, floor, minute, quantity
`"quantity"` - the numeric value of corresponding "units"

- The output will look sorta like this:
```
{
  "commuterId": "COM-123",
  "risk": 5500
}
```
...or it might be an error.  If it's an error, just ask Claude to fix it.

- Risk value is measured in [Micromorts](https://en.wikipedia.org/wiki/Micromort)

## Rules
- each action should have a “timestamp”, “action”, “unit”, and “quantity”
- the timestamps should all be on the same day
- the “action” can be any string
- units should be one of the following: “mile”, “floor”, “minute”, or “quantity”

## Deliverable:
- a runnable prototype that accepts POST requests
- handles input validation
- at least one automated test that you consider valuable