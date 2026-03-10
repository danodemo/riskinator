# RiskinatorAPI©
### Brought to you by Baby Sloth Softworks LLC
#### Written by Dan Nicodemo, not AI

A simple API to help you mitigate risk of death for commuters
---
# HOW MAKE GO?!
Unzip the repo into a folder of your choice, then navigate to the app in your terminal.

You should follow the steps below to make sure Rails will work:

## With Docker
If you have Docker installed, you can run the API without installing Ruby or any dependencies:

**One-time build:**

```bash
docker build -t riskinator .
```

**Single line to run:**

```bash
docker run -p 3000:80 riskinator
```

Or to use port 80 on your host: `docker run -p 80:80 riskinator`. Alternatively, run `docker compose up --build` to build and start in one step (with port 3000 published).

The API is then available at **http://localhost:3000/riskit** (or **http://localhost/riskit** if you used port 80). Example POST:

```bash
curl -X POST http://localhost:3000/riskit \
  -H "Content-Type: application/json" \
  -d '{"commuterId":"COM-123","actions":[{"timestamp":"2022-01-01 10:05:11","action":"walked on sidewalk","unit":"mile","quantity":0.4},{"timestamp":"2022-01-01 10:30:09","action":"rode a shark","unit":"minute","quantity":3}]}'
```

## No Docker? Install Rails 8 and All The Things™
_NOTE: This setup assumes using homebrew_

1.) Install ruby dependencies: `brew install openssl@3 LibYaml gmp rust`

2.) Install `rvm`, `rbenv`, or something like `mise` Ruby version manager: `brew install mise`

3.) install ruby 3.4.2: `mise install ruby@3.4.2` then use it `mise use ruby`

4.) install rails: `gem install rails`

5.) `bundle install` to be sure all dependencies are installed 

6.) If bundle completes successfully you can run `rails s`

7.) Once it's running, hit it with a POST request like it says below

8.) Marvel at the wonders of *Ruby on Rails*

---

# HOW DO RISK ASSESSMENT?!
- You can send a json blob via POST request to `/riskit` from the terminal as follows:

```
curl -X POST http://localhost:3000/riskit \
  -H "Content-Type: application/json" \
  -d '{
    "commuterId": "COM-123",
    "actions": [
      {
        "timestamp": "2022-01-01 10:05:11",
        "action": "walked on sidewalk",
        "unit": "mile",
        "quantity": 2.5
      },
      {
        "timestamp": "2022-01-01 10:30:09",
        "action": "rode a shark",
        "unit": "minute",
        "quantity": 3
      }
    ]
  }'
```

## HOW PARAM?!
- Each riskinator request hash should have the following keys:
`"commuterId"` - a unique string identifier for the commuter in question
`"actions"` - an array of `action_items` (hashes)
**IMPORTANT: each riskinator request hash should include `actions` only for the same given day - different days should be handled in different requests**

- Each `action_item` hash should have the following:
`"timestamp"` - standard DateTime object string
`"action"` - A string with the action to be assessed
`"unit"` - one of the following values in string form: mile, floor, minute, quantity
`"quantity"` - the numeric value of corresponding "units"

- The results will look sorta like this:
```
{
  "commuterId": "COM-123",
  "risk": 5500,
  "valid_actions": 2,
  "invalid_actions": 0
}
```
...or it might be an error.
**NOTE: "invalid" actions refer to actions that don't match anything in the action_map or have mismatched units**

# HOW CALCULATE RISK?!?!
- Risk value is measured in [Micromorts](https://en.wikipedia.org/wiki/Micromort)
- There is an `action_map.yml` in the config that lists the currently supported activities, their associated Units of measurement, and the *increment* of said units that equates to 1 _micromort_ 
- This ultimately leads to the following calculation:
`risk_value = ActionItem["quantity"] / ActionMap["increment"]`

An exmaple entry from the YAML
```
"walked on sidewalk":
    units: mile
    increment: 1
```
For this example, every mile you "walked on sidewalk" would equal one micromort.

- Support new action items by simply adding new entries to the YAML, but keep in mind the entries should be downcased and indented properly
**NOTE: You may need to restart the rails server for the YAML changes to take effect**
- If your request includes some action items that are valid, and some that are not, it will still return the risk value of the valid items --> it will raise a warning in the Rails logger alerting you to the actions that weren't found for later debugging

### Test Requests

You can use the following requests to test the API once it is up and running locally on your machine:

```
# example valid request
curl -X POST http://localhost:3000/riskit \
  -H "Content-Type: application/json" \
  -d '{
    "commuterId": "COM-123",
    "actions": [
      {
        "timestamp": "2022-01-01 10:05:11",
        "action": "walked on sidewalk",
        "unit": "mile",
        "quantity": 2.5
      },
      {
        "timestamp": "2022-01-01 10:30:09",
        "action": "rode a shark",
        "unit": "minute",
        "quantity": 3
      }
    ]
  }'

# example malformed request: failure due to multiple days in action item timestamps (v1)
curl -X POST http://localhost:3000/riskit \
  -H "Content-Type: application/json" \
  -d '{
    "commuterId": "COM-123",
    "actions": [
      {
        "timestamp": "2022-01-02 10:05:11",
        "action": "walked on sidewalk",
        "unit": "mile",
        "quantity": 2.5
      },
      {
        "timestamp": "2022-01-01 10:30:09",
        "action": "rode a shark",
        "unit": "minute",
        "quantity": 3
      }
    ]
  }'

# example malformed request: actions not present in action_map.yml (will still return a risk value as long as some are valid)
curl -X POST http://localhost:3000/riskit \
  -H "Content-Type: application/json" \
  -d '{
    "commuterId": "COM-123",
    "actions": [
      {
        "timestamp": "2022-01-01 10:05:11",
        "action": "walked on a porcupine",
        "unit": "mile",
        "quantity": 2.5
      },
      {
        "timestamp": "2022-01-01 10:30:09",
        "action": "rode a shark",
        "unit": "minute",
        "quantity": 3
      }
    ]
  }'
  ```
